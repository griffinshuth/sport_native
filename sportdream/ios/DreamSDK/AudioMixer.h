//
//  AudioMixer.h
//  sportdream
//
//  Created by lili on 2018/1/31.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVAudioFormat.h>
#import "AACDecode.h"

@interface AudioMixer : NSObject<AACDecodeDelegate>
- (void)initializeAUGraph;

- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue;
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value;
- (void)setOutputVolume:(AudioUnitParameterValue)value;

- (void)startMixer;
- (void)stopMixer;

-(void)commentorConnected:(NSString*)ip;
-(void)commentorDisconnected:(NSString*)ip;
-(void)intoAudioData:(NSData*)data ip:(NSString*)ip;
@end
