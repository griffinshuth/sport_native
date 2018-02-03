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

@interface AudioMixer : NSObject
- (void)initializeAUGraph;

- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue;
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value;
- (void)setOutputVolume:(AudioUnitParameterValue)value;

- (void)startAUGraph;
- (void)stopAUGraph;

-(void)commentorConnected:(NSString*)ip;
-(void)commentorDisconnected:(NSString*)ip;
-(void)intoAudioData:(NSData*)data ip:(NSString*)ip;
@end
