//
//  CameraRecord.h
//  sportdream
//
//  Created by lili on 2017/12/21.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraRecordDelegate <NSObject>
-(void)captureOutput:(NSData*)sampleBuffer frameTime:(CMTime)frameTime;
@end

@interface CameraRecord : NSObject
@property (nonatomic, weak) id <CameraRecordDelegate> delegate;
-(id)initWithPreview:(UIView*)preview width:(int)width height:(int)height;
-(void)startCapture;
-(void)stopCapture;
@end
