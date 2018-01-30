//
//  AACEncode.h
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AACEncodeDelegate <NSObject>
-(void)dataEncodeToAAC:(NSData*)data;
@end

@interface AACEncode : NSObject<AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, weak) id <AACEncodeDelegate> delegate;
-(void)startAACEncodeSession;
-(void)stopAACEncodeSession;
-(void)encodeCMSampleBufferPCMData:(CMSampleBufferRef)sampleBuffer;
-(void)encodeNSDataPCMData:(NSData*)pPCMData;
@end
