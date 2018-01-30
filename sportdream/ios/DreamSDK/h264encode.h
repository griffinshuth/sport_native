//
//  h264encode.h
//  sportdream
//
//  Created by lili on 2017/12/24.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol h264encodeDelegate <NSObject>
//获得编码后的h264数据，不包含头部
-(void)dataEncodeToH264:(const void*)data length:(size_t)length;
-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen;
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame;
@end

@interface h264encode : NSObject
@property (nonatomic, weak) id <h264encodeDelegate> delegate;
-(id)initEncodeWith:(int)w  height:(int)h framerate:(int)fps bitrate:(int)bt;
-(int)startH264EncodeSession;
-(void)encodeH264Frame:(NSData*)sampleBuffer;
-(void)encodeCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)stopH264EncodeSession;
@end
