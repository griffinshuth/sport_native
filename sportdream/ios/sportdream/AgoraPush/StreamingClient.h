//
//  StreamingClient.h
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "h264encode.h"
#import "AACEncode.h"

extern NSTimeInterval const YUVDataSendTimeInterval;
extern NSTimeInterval const PCMDataSendTimeInterval;
extern int const PCMDataSendLength;

@interface StreamingClient : NSObject<h264encodeDelegate,AACEncodeDelegate>
-(void)startStreaming;
-(void)stopStreaming;
- (void)sendYUVData:(unsigned char *)pYUVBuff dataLength:(unsigned int)length;
- (void)sendPCMData:(unsigned char*)pPCMData dataLength:(unsigned int)length;
@end
