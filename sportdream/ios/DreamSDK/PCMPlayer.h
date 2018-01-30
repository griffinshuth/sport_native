//
//  PCMPlayer.h
//  sportdream
//
//  Created by lili on 2018/1/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FileDecoder.h"

@interface PCMPlayer : NSObject <FileDecoderDelegate>
{
  @public
    AudioUnit convertUnit;
}
-(id)initWithFileName:(NSString*)name fileExtension:(NSString*)fileExtension;
- (BOOL)play;
- (void)stop;
-(void)intoAudioData:(NSData*)data;
@end
