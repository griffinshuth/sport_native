//
//  AudioMixer.m
//  sportdream
//
//  Created by lili on 2018/1/31.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AudioMixer.h"

#define MAXBUFS 3
const Float64 kGraphSampleRate = 44100.0;



@interface SoundBuffer:NSObject
@property (nonatomic,strong) NSMutableData* mData;
@property (nonatomic,strong) NSString* ip;
@property (nonatomic,assign) int type;
@property (nonatomic,assign) int subtype;
@property (nonatomic,strong) NSString* deviceID;
@property (nonatomic,strong) NSString* name;
@end

@implementation SoundBuffer

@end

@interface AudioMixer()
 //@property (nonatomic,strong) NSMutableArray<SoundBuffer*>* commentors;
  @property (nonatomic,strong) SoundBuffer* mData1;
  @property (nonatomic,strong) SoundBuffer* mData2;
  @property (nonatomic,strong) SoundBuffer* mData3;
@end

@implementation AudioMixer
{

  AVAudioFormat* mClientFormat;
  AVAudioFormat* mOutputFormat;
  AUGraph mGraph;
  AudioUnit mConverter1;
  AudioUnit mConverter2;
  AudioUnit mConverter3;
  AudioUnit mMixer;
  AudioUnit mConverterSInt16ToFloat32;
  AudioUnit mOutput;
  
  Boolean isPlaying;
  UInt32 audioNums;
}

static OSStatus mixerRenderNotify(void *              inRefCon,
                                  AudioUnitRenderActionFlags *  ioActionFlags,
                                  const AudioTimeStamp *      inTimeStamp,
                                  UInt32              inBusNumber,
                                  UInt32              inNumberFrames,
                                  AudioBufferList *        ioData)
{
  __unsafe_unretained AudioMixer *audoMixer = (__bridge AudioMixer *)inRefCon;
  OSStatus result = noErr;
  
  if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
    [audoMixer RenderNotify:ioData->mBuffers[0]];
  }
  return result;
}

-(void)RenderNotify:(AudioBuffer) buffer
{
  [self.delegate PCMDataAfterMixer:buffer];
}

static OSStatus renderInput1(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
  __unsafe_unretained AudioMixer *audoMixer = (__bridge id)inRefCon;
  return [audoMixer renderData:ioData
                     atTimeStamp:inTimeStamp
                      forElement:0
                    numberFrames:inNumberFrames
                           flags:ioActionFlags];
}

static OSStatus renderInput2(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
  __unsafe_unretained AudioMixer *audoMixer = (__bridge id)inRefCon;
  return [audoMixer renderData:ioData
                   atTimeStamp:inTimeStamp
                    forElement:1
                  numberFrames:inNumberFrames
                         flags:ioActionFlags];
}

static OSStatus renderInput3(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
  __unsafe_unretained AudioMixer *audoMixer = (__bridge id)inRefCon;
  return [audoMixer renderData:ioData
                   atTimeStamp:inTimeStamp
                    forElement:2
                  numberFrames:inNumberFrames
                         flags:ioActionFlags];
}
- (OSStatus)renderData:(AudioBufferList *)ioData
           atTimeStamp:(const AudioTimeStamp *)timeStamp
            forElement:(UInt32)inBusNumber
          numberFrames:(UInt32)numFrames
                 flags:(AudioUnitRenderActionFlags *)flags
{
 
    for(int iBuffer=0;iBuffer<ioData->mNumberBuffers;++iBuffer){
      memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }

    SoundBuffer* buffer = nil;
  if(inBusNumber == 0){
    buffer = self.mData1;
  }else if(inBusNumber == 1){
    buffer = self.mData2;
  }else if(inBusNumber == 2){
    buffer = self.mData3;
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

-(SoundBuffer*)getSoundBufferByIp:(NSString*)ip
{
  if(self.mData1){
    if([self.mData1.ip isEqualToString:ip]){
      return self.mData1;
    }
  }
  
  if(self.mData2){
    if([self.mData2.ip isEqualToString:ip]){
      return self.mData2;
    }
  }
  
  if(self.mData3){
    if([self.mData3.ip isEqualToString:ip]){
      return self.mData3;
    }
  }
  
  return nil;
}

-(void)commentorConnected:(NSString*)ip
{
  SoundBuffer* t = [self getSoundBufferByIp:ip];
  if(t == nil){
    if(self.mData1 == nil){
      self.mData1 = [SoundBuffer alloc];
      self.mData1.mData = [[NSMutableData alloc] init];
      self.mData1.ip = [[NSString alloc] initWithString:ip];
    }else if(self.mData2 == nil){
      self.mData2 = [SoundBuffer alloc];
      self.mData2.mData = [[NSMutableData alloc] init];
      self.mData2.ip = [[NSString alloc] initWithString:ip];
    }else if(self.mData3 == nil){
      self.mData3 = [SoundBuffer alloc];
      self.mData3.mData = [[NSMutableData alloc] init];
      self.mData3.ip = [[NSString alloc] initWithString:ip];
    }
    
  }
}

-(void)commentorDisconnected:(NSString*)ip
{
  SoundBuffer* t = [self getSoundBufferByIp:ip];
  if(t == self.mData1){
    self.mData1 = nil;
  }else if(t == self.mData2){
    self.mData2 = nil;
  }else if(t == self.mData3){
    self.mData3 = nil;
  }
}

-(void)intoAudioData:(NSData*)data ip:(NSString*)ip
{
  SoundBuffer* t = [self getSoundBufferByIp:ip];
  if(t){
    if(t == self.mData1){
      @synchronized(self.mData1){
        [self.mData1.mData appendData:data];
      }
    }else if(t == self.mData2){
      @synchronized(self.mData2){
        [self.mData2.mData appendData:data];
      }
    }else if(t == self.mData3){
      @synchronized(self.mData3){
        [self.mData3.mData appendData:data];
      }
    }
  }
}

//delegate
-(void)AACDecodeToPCM:(NSData*)data  SocketName:(NSString*)SocketName
{
  
}


-(id)init
{
  self = [super init];
  if(self){
    [self initializeAUGraph];
    isPlaying = false;
    audioNums = 2;
    [self startMixer];
    //AudioUnitParameterValue isOn = false;
    //[self enableInput:0 isOn:isOn];
  }
  return self;
}

-(void)dealloc
{
  if(isPlaying){
    [self stopMixer];
  }
}

-(void)initializeAUGraph
{
  AUNode convertNode1;
  AUNode convertNode2;
  AUNode convertNode3;
  AUNode mixerNode;
  AUNode mConverterSInt16ToFloat32Node;
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
  result = AUGraphAddNode(mGraph, &convertDescription, &convertNode3);
  result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode);
  result = AUGraphAddNode(mGraph, &convertDescription, &mConverterSInt16ToFloat32Node);
  result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
  if(result<0){
    NSLog(@"error");
  }

  result = AUGraphOpen(mGraph);
  
  result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
  result = AUGraphNodeInfo(mGraph, convertNode1, NULL, &mConverter1);
  result = AUGraphNodeInfo(mGraph, convertNode2, NULL, &mConverter2);
  result = AUGraphNodeInfo(mGraph, convertNode3, NULL, &mConverter3);
  result = AUGraphNodeInfo(mGraph, mConverterSInt16ToFloat32Node, NULL, &mConverterSInt16ToFloat32);
  result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutput);
  
    AURenderCallbackStruct rcbs;
    rcbs.inputProc = &renderInput1;
    rcbs.inputProcRefCon = (__bridge void*) self;
  
  AURenderCallbackStruct rcbs2;
  rcbs2.inputProc = &renderInput2;
  rcbs2.inputProcRefCon = (__bridge void*) self;
  
  AURenderCallbackStruct rcbs3;
  rcbs3.inputProc = &renderInput3;
  rcbs3.inputProcRefCon = (__bridge void*) self;
    
    //result = AUGraphSetNodeInputCallback(mGraph, convertNode1, 0, &rcbs);
    //result = AUGraphSetNodeInputCallback(mGraph, convertNode2, 1, &rcbs2);
  result = AudioUnitSetProperty(mConverter1, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                &rcbs, sizeof(rcbs));
  result = AudioUnitSetProperty(mConverter2, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                &rcbs2, sizeof(rcbs2));
  
  result = AudioUnitSetProperty(mConverter3, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                &rcbs3, sizeof(rcbs3));
  
  
  result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &audioNums, sizeof(audioNums));
  
  result = AudioUnitSetProperty(mConverter1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  result = AudioUnitSetProperty(mConverter1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AudioUnitSetProperty(mConverter2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  result = AudioUnitSetProperty(mConverter2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AudioUnitSetProperty(mConverter3, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  result = AudioUnitSetProperty(mConverter3, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  for(int i=0;i<audioNums;i++){
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  }
  result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AudioUnitSetProperty(mConverterSInt16ToFloat32, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, mClientFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  result = AudioUnitSetProperty(mConverterSInt16ToFloat32, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
 
  result = AudioUnitSetProperty(mOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, mOutputFormat.streamDescription, sizeof(AudioStreamBasicDescription));
  
  result = AUGraphConnectNodeInput(mGraph, convertNode1, 0, mixerNode, 0);
  result = AUGraphConnectNodeInput(mGraph, convertNode2, 0, mixerNode, 1);
  result = AUGraphConnectNodeInput(mGraph, convertNode3, 0, mixerNode, 2);
  result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, mConverterSInt16ToFloat32Node, 0);
  result = AUGraphConnectNodeInput(mGraph, mConverterSInt16ToFloat32Node, 0, outputNode, 0);
  
  AudioUnitAddRenderNotify(mMixer, &mixerRenderNotify, (__bridge void *)self);
  
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
- (void)startMixer
{
  if(isPlaying){
    return;
  }
  OSStatus result = AUGraphStart(mGraph);
  if (result) { printf("AUGraphStart result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result); return; }
  isPlaying = true;
}

// stops render
- (void)stopMixer
{
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
















































