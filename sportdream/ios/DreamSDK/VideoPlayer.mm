//
//  VideoPlayer.m
//  sportdream
//
//  Created by lili on 2018/4/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "VideoPlayer.h"
#import "AAPLEAGLLayer.h"
#import "pool_av_user.h"

static OSStatus mixerRenderNotify(void *              inRefCon,
                                  AudioUnitRenderActionFlags *  ioActionFlags,
                                  const AudioTimeStamp *      inTimeStamp,
                                  UInt32              inBusNumber,
                                  UInt32              inNumberFrames,
                                  AudioBufferList *        ioData)
{
  __unsafe_unretained VideoPlayer *THIS = (__bridge VideoPlayer *)inRefCon;
  OSStatus result = noErr;
  
  if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
    [pool_av_user sendAudioDataToPool:ioData->mBuffers[0].mData length:ioData->mBuffers[0].mDataByteSize];
  }
  return result;
}

static const AudioUnitElement inputElement = 1;

@interface VideoPlayer()
@property (nonatomic,strong) NSMutableData* audioBuffer;
@end

@implementation VideoPlayer
{
  BOOL isStart;
  BOOL isPreviewing;
  BOOL isPushing;
  BOOL isFirstAudioFrameReady;
  FileDecoder* fileDecoder;
  UIView* playbackView;
  AAPLEAGLLayer* _glLayer;
  
  AUGraph graph;
  AUNode remoteIONode;    //接收单通道F32数据用于播放
  AudioUnit remoteIOUnit;
  AUNode convertChannelNode;     //双通道转单通道
  AudioUnit convertChannelUnit;
  AUNode convertNode;         //单通道S16转单通道F32,用于播放
  AudioUnit convertUnit;
  
  Float64 sampleRate;
  Float64 channels;
  CGFloat currentAudioTime;
  CMSampleBufferRef fileVideoSampleBuffer;
  CGFloat currentVideoTimestamp;
  dispatch_semaphore_t semaphore;
  int pushFrameCount;
}

//delegate
- (void)didCompletePlayingMovie
{
  if(isStart){
    [self stop];
  }
}
- (void)didVideoOutput:(CMSampleBufferRef)videoData
{
  fileVideoSampleBuffer = videoData;
  CMTime currentVideoSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(fileVideoSampleBuffer);
  currentVideoTimestamp = CMTimeGetSeconds(currentVideoSampleTime);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if(isStart){
      [self processVideo];
      [fileDecoder readNextVideoFrameFromOutput];
    }

  });
  /*if(isPushing){
    [self.delegate didVideoOutput:videoData];
  }else{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoData);
    dispatch_sync(dispatch_get_main_queue(), ^{
      _glLayer.pixelBuffer = pixelBuffer;
    });
  }
  //CMSampleBufferInvalidate(videoData);
  CFRelease(videoData);*/
}
- (void)didAudioOutput:(CMSampleBufferRef)audioData
{
  CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(audioData);
  AudioBufferList audioBufferList;
  
  CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioData,
                                                          NULL,
                                                          &audioBufferList,
                                                          sizeof(audioBufferList),
                                                          NULL,
                                                          NULL,
                                                          kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                          &buffer
                                                          );
  void* data = audioBufferList.mBuffers[0].mData;
  NSUInteger len = audioBufferList.mBuffers[0].mDataByteSize;
  //读取采样率和声道数
  CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(audioData);
  const AudioStreamBasicDescription* asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
  sampleRate = asbd->mSampleRate;
  channels = asbd->mChannelsPerFrame;
  
  if(!isFirstAudioFrameReady){
    isFirstAudioFrameReady = true;
    //初始化音频处理逻辑
    [self createAUGraph];
    OSStatus status = AUGraphStart(graph);
    CheckStatus(status, @"Could not start AUGraph");
  }
  
  @synchronized(self.audioBuffer){
    [self.audioBuffer appendBytes:data length:len];
    CFRelease(buffer);
  }
  [fileDecoder readNextAudioSampleFromOutput];
}

-(void)processVideo
{
  if(isPushing){
    pushFrameCount++;
    if(pushFrameCount%4 !=0){
      [self.delegate didVideoOutput:fileVideoSampleBuffer];
    }else{
      NSLog(@"ignore video frame");
    }
  }else{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(fileVideoSampleBuffer);
    //dispatch_sync(dispatch_get_main_queue(), ^{
      _glLayer.pixelBuffer = pixelBuffer;
    //});
  }
  //CMSampleBufferInvalidate(fileVideoSampleBuffer);
  CFRelease(fileVideoSampleBuffer);
}

-(id)init
{
  self = [super init];
  if(self){
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    [mySession setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    isStart = FALSE;
    isPreviewing = FALSE;
    isPushing = FALSE;
    isFirstAudioFrameReady = FALSE;
    currentAudioTime = 0;
    pushFrameCount = 0;
  }
  return self;
}

-(void)dealloc
{
  
}

-(void)startPreview:(NSString*)filename fileExtension:(NSString*)fileExtension view:(UIView*)view
{
  if(isStart){
    return;
  }
  NSURL *fileURL = [[NSBundle mainBundle] URLForResource:filename withExtension:fileExtension];
  fileDecoder = [[FileDecoder alloc] initWithURL:fileURL];
  fileDecoder.delegate = self;
  fileDecoder.playAtActualSpeed = true;
  
  self.audioBuffer = [[NSMutableData alloc] init];
  
  playbackView = view;
  _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, playbackView.frame.size.width, playbackView.frame.size.height)];
  [playbackView.layer addSublayer:_glLayer];
  [fileDecoder startProcessing];
  isPreviewing = true;
  isStart = true;
  semaphore = dispatch_semaphore_create(0);
}

-(void)startPush:(NSString*)filename fileExtension:(NSString*)fileExtension
{
  if(isStart){
    return;
  }
  NSURL *fileURL = [[NSBundle mainBundle] URLForResource:filename withExtension:fileExtension];
  fileDecoder = [[FileDecoder alloc] initWithURL:fileURL withPixelType:kCVPixelFormatType_32BGRA];
  fileDecoder.delegate = self;
  fileDecoder.playAtActualSpeed = true;
  self.audioBuffer = [[NSMutableData alloc] init];
  [fileDecoder startProcessing];
  isPushing = true;
  isStart = true;
  semaphore = dispatch_semaphore_create(0);
  pushFrameCount = 0;
  currentAudioTime = 0;
}

-(BOOL)isStop
{
  return !isStart;
}

-(void)stop
{
  isStart = FALSE;
  isPreviewing = FALSE;
  isPushing = FALSE;
  [fileDecoder cancelProcessing];
  if(isFirstAudioFrameReady){
    [self destroyAudioUnitGraph];
    isFirstAudioFrameReady = FALSE;
  }
  self.audioBuffer = nil;
  dispatch_semaphore_signal(semaphore);
}

-(void)createAUGraph
{
  OSStatus status = noErr;
  status = NewAUGraph(&graph);
  CheckStatus(status,@"Could not create a new AUGraph");
  
  [self addAudioUnitNodes];
  
  status = AUGraphOpen(graph);
  CheckStatus(status, @"Could not open AUGraph");
  
  [self getUnitsFromNodes];
  
  [self setAudioUnitProperties];
  
  [self makeNodeConnections];
  
  CAShow(graph);
  
  status = AUGraphInitialize(graph);
  CheckStatus(status, @"Could not initialize AUGraph");
  
}

-(void)addAudioUnitNodes
{
  OSStatus status = noErr;
  AudioComponentDescription ioDescription;
  bzero(&ioDescription, sizeof(ioDescription));
  ioDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
  ioDescription.componentType = kAudioUnitType_Output;
  ioDescription.componentSubType = kAudioUnitSubType_RemoteIO;
  
  status = AUGraphAddNode(graph, &ioDescription, &remoteIONode);
  CheckStatus(status, @"Could not add I/O node to AUGraph");
  
  AudioComponentDescription convertChannelDescription;
  bzero(&convertChannelDescription, sizeof(convertChannelDescription));
  convertChannelDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
  convertChannelDescription.componentType = kAudioUnitType_FormatConverter;
  convertChannelDescription.componentSubType = kAudioUnitSubType_AUConverter;
  status = AUGraphAddNode(graph, &convertChannelDescription, &convertChannelNode);
  CheckStatus(status, @"Could not add convertChannelNode to AUGraph");
  
  AudioComponentDescription convertDescription;
  bzero(&convertDescription, sizeof(convertDescription));
  convertDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
  convertDescription.componentType = kAudioUnitType_FormatConverter;
  convertDescription.componentSubType = kAudioUnitSubType_AUConverter;
  status = AUGraphAddNode(graph, &convertDescription, &convertNode);
  CheckStatus(status, @"Could not add Convert node to AUGraph");
}

-(void)getUnitsFromNodes
{
  OSStatus status = noErr;
  status = AUGraphNodeInfo(graph, remoteIONode, NULL, &remoteIOUnit);
  CheckStatus(status, @"Could not retrieve node info for I/O node");
  
  status = AUGraphNodeInfo(graph, convertChannelNode, NULL, &convertChannelUnit);
  CheckStatus(status, @"Could not retrieve node info for convertChannelNode");
  
  status = AUGraphNodeInfo(graph, convertNode, NULL, &convertUnit);
  CheckStatus(status, @"Could not retrieve node info for Convert node");
}

-(void)setAudioUnitProperties
{
  OSStatus status = noErr;
  AudioStreamBasicDescription _clientFormat16int;
  UInt32 bytesPerSample = sizeof (SInt16);
  bzero(&_clientFormat16int, sizeof(_clientFormat16int));
  _clientFormat16int.mFormatID          = kAudioFormatLinearPCM;
  _clientFormat16int.mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
  _clientFormat16int.mBytesPerPacket    = bytesPerSample * channels;
  _clientFormat16int.mFramesPerPacket   = 1;
  _clientFormat16int.mBytesPerFrame     = bytesPerSample * channels;
  _clientFormat16int.mChannelsPerFrame  = channels;
  _clientFormat16int.mBitsPerChannel    = 8 * bytesPerSample;
  _clientFormat16int.mSampleRate        = sampleRate;
  
  int convertChannel = 1;
  AudioStreamBasicDescription _clientFormat1Channel16int;
  bzero(&_clientFormat1Channel16int, sizeof(_clientFormat1Channel16int));
  _clientFormat1Channel16int.mFormatID          = kAudioFormatLinearPCM;
  _clientFormat1Channel16int.mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
  _clientFormat1Channel16int.mBytesPerPacket    = bytesPerSample * convertChannel;
  _clientFormat1Channel16int.mFramesPerPacket   = 1;
  _clientFormat1Channel16int.mBytesPerFrame     = bytesPerSample * convertChannel;
  _clientFormat1Channel16int.mChannelsPerFrame  = convertChannel;
  _clientFormat1Channel16int.mBitsPerChannel    = 8 * bytesPerSample;
  _clientFormat1Channel16int.mSampleRate        = sampleRate;
  
  AudioStreamBasicDescription streamFormat = [self nonInterleavedPCMFormatWithChannels:1];
  
  //双通道转单通道
  status = AudioUnitSetProperty(convertChannelUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_clientFormat1Channel16int, sizeof(_clientFormat1Channel16int));
  CheckStatus(status, @"augraph recorder normal unit set client format error");
  status = AudioUnitSetProperty(convertChannelUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_clientFormat16int, sizeof(_clientFormat16int));
  CheckStatus(status, @"augraph recorder normal unit set client format error");
  
  //SInt16转Float32
  status = AudioUnitSetProperty(convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat));
  CheckStatus(status, @"augraph recorder normal unit set client format error");
  status = AudioUnitSetProperty(convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_clientFormat1Channel16int, sizeof(_clientFormat1Channel16int));
  CheckStatus(status, @"augraph recorder normal unit set client format error");
  
  //播放
  status = AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement, &streamFormat, sizeof(streamFormat));
  CheckStatus(status, @"Could not set stream format on I/O unit output scope");
}

- (AudioStreamBasicDescription)nonInterleavedPCMFormatWithChannels:(UInt32)channels
{
  UInt32 bytesPerSample = sizeof(Float32);
  AudioStreamBasicDescription asbd;
  bzero(&asbd, sizeof(asbd));
  asbd.mSampleRate = sampleRate;
  asbd.mFormatID = kAudioFormatLinearPCM;
  asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
  asbd.mBitsPerChannel = 8*bytesPerSample;
  asbd.mBytesPerFrame = bytesPerSample;
  asbd.mBytesPerPacket = bytesPerSample;
  asbd.mFramesPerPacket = 1;
  asbd.mChannelsPerFrame = channels;
  return asbd;
}

-(void)makeNodeConnections
{
  OSStatus status = noErr;
  status = AUGraphConnectNodeInput(graph, convertChannelNode, 0, convertNode, 0);
  status = AUGraphConnectNodeInput(graph, convertNode, 0, remoteIONode, 0);
  CheckStatus(status, @"Could not connect I/O node input to mixer node input");
  
  AURenderCallbackStruct callbackStruct;
  callbackStruct.inputProc = &InputRenderCallback;
  callbackStruct.inputProcRefCon = (__bridge void*) self;
  AUGraphSetNodeInputCallback(graph, convertChannelNode, 0, &callbackStruct);
  //status = AudioUnitSetProperty(convertUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
  //&callbackStruct, sizeof(callbackStruct));
  AudioUnitAddRenderNotify(convertChannelUnit, &mixerRenderNotify, (__bridge void *)self);
  CheckStatus(status, @"Could not set render callback on mixer input scope, element 1");
}

- (void)destroyAudioUnitGraph
{
  AUGraphStop(graph);
  AUGraphUninitialize(graph);
  AUGraphClose(graph);
  AUGraphRemoveNode(graph, remoteIONode);
  DisposeAUGraph(graph);
  remoteIOUnit = NULL;
  remoteIONode = 0;
  graph = NULL;
}

- (OSStatus)renderData:(AudioBufferList *)ioData
           atTimeStamp:(const AudioTimeStamp *)timeStamp
            forElement:(UInt32)element
          numberFrames:(UInt32)numFrames
                 flags:(AudioUnitRenderActionFlags *)flags
{
  if(!isStart){
    return noErr;
  }
  @autoreleasepool{
    for(int iBuffer=0;iBuffer<ioData->mNumberBuffers;++iBuffer){
      memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    NSUInteger needLen = 0;
    UInt32 bytesPerSample = sizeof (SInt16);
    if(self.audioBuffer.length<numFrames*bytesPerSample*channels){
      needLen = self.audioBuffer.length;
    }else{
      needLen = numFrames*bytesPerSample*channels;
    }
    if(needLen == 0){
      return noErr;
    }
    @synchronized(self.audioBuffer){
      for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memcpy((SInt16 *)ioData->mBuffers[iBuffer].mData, self.audioBuffer.bytes, needLen);
      }
      [self.audioBuffer replaceBytesInRange:NSMakeRange(0, needLen) withBytes:NULL length:0];
    }
    currentAudioTime += (CGFloat)numFrames/sampleRate;
    if(currentAudioTime>currentVideoTimestamp){
      dispatch_semaphore_signal(semaphore);
    }
    return noErr;
  }
}

static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
  VideoPlayer *audioOutput = (__bridge id)inRefCon;
  return [audioOutput renderData:ioData
                     atTimeStamp:inTimeStamp
                      forElement:inBusNumber
                    numberFrames:inNumberFrames
                           flags:ioActionFlags];
}

static void CheckStatus(OSStatus status, NSString *message)
{
  if(status != noErr)
  {
    char fourCC[16];
    *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
    fourCC[4] = '\0';
    
    if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
      NSLog(@"%@: %s", message, fourCC);
    else
      NSLog(@"%@: %d", message, (int)status);
  }
}

@end
