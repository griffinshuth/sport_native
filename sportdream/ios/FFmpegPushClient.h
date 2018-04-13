//
//  FFmpegPushClient.h
//  sportdream
//
//  Created by lili on 2018/4/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "h264encode.h"

@interface FFmpegPushClient : NSObject<h264encodeDelegate>
-(void)startStreaming;
-(void)stopStreaming;
-(BOOL)isPushing;
- (void)sendYUVData:(unsigned char *)pYUVBuff dataLength:(unsigned int)length;
- (void)sendRGBAData:(unsigned char *)pRGBABuff dataLength:(unsigned int)length;
- (void)sendPCMData:(unsigned char*)pPCMData dataLength:(unsigned int)length;
@end
