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
@optional
-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds;
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts;
-(void)rtmpSmallSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds;
-(void)rtmpSmallH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts;
@end

@interface h264encode : NSObject
@property (nonatomic, weak) id <h264encodeDelegate> delegate;
-(id)initEncodeWith:(int)w  height:(int)h framerate:(int)fps bitrate:(int)bt;
-(id)initSmallEncodeWith:(int)w  height:(int)h framerate:(int)fps bitrate:(int)bt;
-(int)startH264EncodeSession;
-(void)encodeH264Frame:(NSData*)NV12Data;
-(void)encodeCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)encodeBytes:(unsigned char *)BGRAData;
-(void)stopH264EncodeSession;
@end
