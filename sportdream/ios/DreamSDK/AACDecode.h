//
//  AACDecode.h
//  sportdream
//
//  Created by lili on 2018/1/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AACDecodeDelegate <NSObject>
-(void)AACDecodeToPCM:(NSData*)data;
@end

@interface AACDecode : NSObject
@property (nonatomic, weak) id <AACDecodeDelegate> delegate;
-(void)stopAACEncodeSession;
-(void)decodeAudioFrame:(NSData *)frame;
@end
