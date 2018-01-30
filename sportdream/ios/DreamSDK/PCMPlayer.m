//
//  PCMPlayer.m
//  sportdream
//
//  Created by lili on 2018/1/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "PCMPlayer.h"

static OSStatus mixerRenderNotify(void *              inRefCon,
                                  AudioUnitRenderActionFlags *  ioActionFlags,
                                  const AudioTimeStamp *      inTimeStamp,
                                  UInt32              inBusNumber,
                                  UInt32              inNumberFrames,
                                  AudioBufferList *        ioData)
{
  __unsafe_unretained PCMPlayer *THIS = (__bridge PCMPlayer *)inRefCon;
  OSStatus result = noErr;
 
  if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
    
  }
  return result;
}

static const AudioUnitElement inputElement = 1;

@interface PCMPlayer()
@property (nonatomic,strong) FileDecoder* fileDecoder;
@property (nonatomic,strong) NSMutableData* audioBuffer;
@end

@implementation PCMPlayer
{
  AUGraph graph;
  AUNode remoteIONode;
  AudioUnit remoteIOUnit;
  AUNode convertNode;
  
  Float64 sampleRate;
  Float64 channels;
  
  BOOL isHaveFile;
}

- (void)didCompletePlayingMovie
{
  
}
- (void)didVideoOutput:(CMSampleBufferRef)videoData
{
  
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
  @synchronized(self.audioBuffer){
    [self.audioBuffer appendBytes:data length:len];
  }
}

-(void)intoAudioData:(NSData*)data
{
  @synchronized(self.audioBuffer){
    [self.audioBuffer appendData:data];
  }
}

-(id)initWithFileName:(NSString*)name fileExtension:(NSString*)fileExtension
{
  self = [super init];
  if(self){
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    [mySession setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    sampleRate = 44100;
    channels = 1;
    self.audioBuffer = [[NSMutableData alloc] init];
    [self createAUGraph];
    if(name && fileExtension){
      isHaveFile = true;
      NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:name withExtension:fileExtension];
      self.fileDecoder = [[FileDecoder alloc] initWithURL:sampleURL];
      self.fileDecoder.delegate = self;
      self.fileDecoder.playAtActualSpeed = false;
    }else{
      isHaveFile = false;
    }
  }
  return self;
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
  
  status = AUGraphNodeInfo(graph, convertNode, NULL, &convertUnit);
  CheckStatus(status, @"Could not retrieve node info for Convert node");
}

-(void)setAudioUnitProperties
{
  OSStatus status = noErr;
  AudioStreamBasicDescription streamFormat = [self nonInterleavedPCMFormatWithChannels:channels];
  status = AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement, &streamFormat, sizeof(streamFormat));
  CheckStatus(status, @"Could not set stream format on I/O unit output scope");
  
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
  
  status = AudioUnitSetProperty(convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat));
  CheckStatus(status, @"augraph recorder normal unit set client format error");
  status = AudioUnitSetProperty(convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_clientFormat16int, sizeof(_clientFormat16int));
  CheckStatus(status, @"augraph recorder normal unit set client format error");
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
  status = AUGraphConnectNodeInput(graph, convertNode, 0, remoteIONode, 0);
  CheckStatus(status, @"Could not connect I/O node input to mixer node input");
  
  AURenderCallbackStruct callbackStruct;
  callbackStruct.inputProc = &InputRenderCallback;
  callbackStruct.inputProcRefCon = (__bridge void*) self;
  AUGraphSetNodeInputCallback(graph, convertNode, 0, &callbackStruct);
  //status = AudioUnitSetProperty(convertUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                //&callbackStruct, sizeof(callbackStruct));
  AudioUnitAddRenderNotify(remoteIOUnit, &mixerRenderNotify, (__bridge void *)self);
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

- (BOOL)play
{
  if(isHaveFile){
    [self.fileDecoder startProcessing];
  }
  OSStatus status = AUGraphStart(graph);
  CheckStatus(status, @"Could not start AUGraph");
  return YES;
}

- (void)stop
{
  if(isHaveFile){
    [self.fileDecoder cancelProcessing];
  }
  OSStatus status = AUGraphStop(graph);
  CheckStatus(status, @"Could not stop AUGraph");
}

-(void)dealloc
{
  [self destroyAudioUnitGraph];
}

- (OSStatus)renderData:(AudioBufferList *)ioData
           atTimeStamp:(const AudioTimeStamp *)timeStamp
            forElement:(UInt32)element
          numberFrames:(UInt32)numFrames
                 flags:(AudioUnitRenderActionFlags *)flags
{
  @autoreleasepool{
    for(int iBuffer=0;iBuffer<ioData->mNumberBuffers;++iBuffer){
      memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    NSUInteger needLen = 0;
    UInt32 bytesPerSample = sizeof (SInt16);
    if(self.audioBuffer.length<numFrames*bytesPerSample){
      needLen = self.audioBuffer.length;
    }else{
      needLen = numFrames*bytesPerSample;
    }
    if(needLen == 0){
      return noErr;
    }
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
      memcpy((SInt16 *)ioData->mBuffers[iBuffer].mData, self.audioBuffer.bytes, needLen);
    }
    @synchronized(self.audioBuffer){
      [self.audioBuffer replaceBytesInRange:NSMakeRange(0, needLen) withBytes:NULL length:0];
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
  PCMPlayer *audioOutput = (__bridge id)inRefCon;
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
