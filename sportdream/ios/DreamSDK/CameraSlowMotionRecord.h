//
//  CameraSlowMotionRecord.h
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol CameraSlowMotionRecordDelegate <NSObject>
-(void)captureOutput:(CMSampleBufferRef)sampleBuffer;
@end

@interface CameraSlowMotionRecord : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) id <CameraSlowMotionRecordDelegate> delegate;
-(id)initWithPreview:(UIView*)preview isSlowMotion:(BOOL)isSlowMotion;
-(void)startCapture;
-(void)stopCapture;
-(void)zoom:(float)scale;
@end
