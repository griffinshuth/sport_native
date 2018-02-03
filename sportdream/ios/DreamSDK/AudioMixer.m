//
//  AudioMixer.m
//  sportdream
//
//  Created by lili on 2018/1/31.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AudioMixer.h"

#define MAXBUFS 2
const Float64 kGraphSampleRate = 44100.0;

@interface SoundBuffer:NSObject
@property (nonatomic,strong) NSMutableData* mData;
@property (nonatomic,strong) NSString* ip;
@end

@implementation SoundBuffer

@end

@interface AudioMixer()
 @property (nonatomic,strong) NSMutableArray<SoundBuffer*>* commentors;
@end

@implementation AudioMixer
{

  AVAudioFormat* mClientFormat;
  AVAudioFormat* mOutputFormat;
  AUGraph mGraph;
  AudioUnit mConverter1;
  AudioUnit mConverter2;
  AudioUnit mMixer;
  AudioUnit mOutput;
  
  Boolean isPlaying;
}

static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
  AudioMixer *audoMixer = (__bridge id)inRefCon;
  return [audoMixer renderData:ioData
                     atTimeStamp:inTimeStamp
                      forElement:0
                    numberFrames:inNumberFrames
                           flags:ioActionFlags];
}

static OSStatus renderInput2(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
  AudioMixer *audoMixer = (__bridge id)inRefCon;
  return [audoMixer renderData:ioData
                   atTimeStamp:inTimeStamp
                    forElement:1
                  numberFrames:inNumberFrames
                         flags:ioActionFlags];
}
- (OSStatus)renderData:(AudioBufferList *)ioData
           atTimeStamp:(const AudioTimeStamp *)timeStamp
            forElement:(UInt32)inBusNumber
          numberFrames:(UInt32)numFrames
                 flags:(AudioUnitRenderActionFlags *)flags
{
  //静音
  for(int iBuffer=0;iBuffer<ioData->mNumberBuffers;++iBuffer){
    memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
  }
  SoundBuffer* buffer = [self.commentors objectAtIndex:inBusNumber];
  if(inBusNumber == 1){
    
  }
  if(buffer){
    NSUInteger needLen = 0;
    UInt32 bytesPerSample = sizeof (SInt16);
    if(buffer.mData.length < numFrames*bytesPerSample){
      needLen = buffer.mData.length;
    }else{
      needLen = numFrames*bytesPerSample;
    }
    if(needLen == 0){
      return noErr;
    }
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
      memcpy(ioData->mBuffers[iBuffer].mData, buffer.mData.bytes, needLen);
    }
    @synchronized(buffer){
      [buffer.mData replaceBytesInRange:NSMakeRange(0, needLen) withBytes:NULL length:0];
    }
  }
  return noErr;
}

-(void)commentorConnected:(NSString*)ip
{
  //判断IP是否已经存在
  for(SoundBuffer* buffer in self.commentors){
    if([buffer.ip isEqualToString:ip]){
      return;
    }
  }
  
  SoundBuffer* b = [SoundBuffer alloc];
  b.mData = [[NSMutableData alloc] init];
  b.ip = [[NSString alloc] initWithString:ip];
  [self.commentors addObject:b];
}

-(void)commentorDisconnected:(NSString*)ip
{
  for(SoundBuffer* buffer in self.commentors){
    if([buffer.ip isEqualToString:ip]){
      [self.commentors removeObject:buffer];
      break;
    }
  }
}

-(void)intoAudioData:(NSData*)data ip:(NSString*)ip
{
  for(SoundBuffer* buffer in self.commentors){
    if([buffer.ip isEqualToString:ip]){
      @synchronized(buffer){
        [buffer.mData appendData:data];
      }
      break;
    }
  }
}


-(id)init
{
  self = [super init];
  if(self){
    self.commentors = [[NSMutableArray alloc] init];
    [self initializeAUGraph];
    [self startAUGraph];
    //AudioUnitParameterValue isOn = false;
    //[self enableInput:0 isOn:isOn];
  }
  return self;
}

-(void)dealloc
{
  [self stopAUGraph];
}

-(void)initializeAUGraph
{
  AUNode convertNode1;
  AUNode convertNode2;
  AUNode mixerNode;
  AUNode outputNode;
  
  mClientFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                   sampleRate:kGraphSampleRate
                                                     channels:1
                                                  interleaved:NO];
  mOutputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                   sampleRate:kGraphSampleRate
                                                     channels:1
                                                  interleaved:NO];
  
  OSStatus result = noErr;
  result = NewAUGraph(&mGraph);
  
  AudioComponentDescription output_desc;
  bzero(&output_desc, sizeof(output_desc));
  output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  output_desc.componentType = kAudioUnitType_Output;
  output_desc.componentSubType = kAudioUnitSubType_RemoteIO;
  
  AudioComponentDescription convertDescription;
  bzero(&convertDescription, sizeof(convertDescription));
  convertDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
  convertDescription.componentType = kAudioUnitType_FormatConverter;
  convertDescription.componentSubType = kAudioUnitSubType_AUConverter;
  
  AudioComponentDescription mixer_desc;
  bzero(&mixer_desc, sizeof(mixer_desc));
  mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
  mixer_desc.componentType = kAudioUnitType_Mixer;
  mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
  
  result = AUGraphAddNode(mGraph, &convertDescription, &convertNode1);
  result = AUGraphAddNode(mGraph, &convertDescription, &convertNode2);
  result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode);
  result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
  if(result<0){
    NSLog(@"error");
  }

  if(result<0){
    NSLog(@"error");
  }
  //result = AUGraphConnectNodeInput(mGraph, convertNode, 0, outputNode, 0);
  
  result = AUGraphOpen(mGraph);
  
  result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
  result = AUGraphNodeInfo(mGraph, convertNode1, NULL, &mConverter1);
  result = AUGraphNodeInfo(mGraph, convertNode2, NULL, &mConverter2);
  result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutput);
  
    AURenderCallbackStruct rcbs;
    rcbs.inputProc = &renderInput;
    rcbs.inputProcRefCon = (__bridge void*) self;
  
  AURenderCallbackStruct rcbs2;
  rcbs2.inputProc = &renderInput2;
  rcbs2.inputProcRefCon = (__bridge void*) self;
    
    //result = AUGraphSetNodeInputCallback(mGraph, convertNode1, 0, &rcbs);
    //result = AUGraphSetNodeInputCallback(mGraph, convertNode2, 1, &rcbs2);
  result = AudioUnitSetProperty(mConverter1, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                &rcbs, sizeof(rcbs));
  result = AudioUnitSetProperty(mConverter2, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                &rcbs2, sizeof(rcbs2));
  
  UInt32 numbuses = 2;
  result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, sizeof(numbuses));
  result = AudioUnitSetProperty(mConverter1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AudioUnitSetProperty(mConverter1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AudioUnitSetProperty(mConverter2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AudioUnitSetProperty(mConverter2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  for(int i=0;i<numbuses;i++){
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  }
  
  
  result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
 
  result = AudioUnitSetProperty(mOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AUGraphConnectNodeInput(mGraph, convertNode1, 0, mixerNode, 0);
  result = AUGraphConnectNodeInput(mGraph, convertNode2, 0, mixerNode, 1);
  result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, outputNode, 0);
  
  result = AUGraphInitialize(mGraph);
}

#pragma mark-

// enable or disables a specific bus
- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue
{
  printf("BUS %d isON %f\n", (unsigned int)inputNum, isONValue);
  
  OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
  if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Enable result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
  
}

// sets the input volume for a specific bus
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value
{
  OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, value, 0);
  if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}

// sets the overall mixer output volume
- (void)setOutputVolume:(AudioUnitParameterValue)value
{
  OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
  if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Output result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
}

// stars render
- (void)startAUGraph
{
  printf("PLAY\n");
  
  OSStatus result = AUGraphStart(mGraph);
  if (result) { printf("AUGraphStart result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
  isPlaying = true;
}

// stops render
- (void)stopAUGraph
{
  printf("STOP\n");
  
  Boolean isRunning = false;
  
  OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
  if (result) { printf("AUGraphIsRunning result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
  
  if (isRunning) {
    result = AUGraphStop(mGraph);
    if (result) { printf("AUGraphStop result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
    isPlaying = false;
  }
}

@end
















































