//
//  h264decode.h
//  sportdream
//
//  Created by lili on 2017/12/28.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol PostProgressDelegate <NSObject>
-(void)dataFromPostProgress:(NSData*)pixelBuf frameTime:(CMTime)frameTime;
@end

@interface h264decode : NSObject
@property (nonatomic, weak) id <PostProgressDelegate> delegate;
-(id)initWithView:(UIView*)view;
-(id)initWithGPUImageView:(UIView*)preview;
-(void)setPreview:(UIView*)view;
-(void)decodeH264:(NSData*)nalu;  //待解码的h264信息，包含头部信息
-(void)decodeH264WithoutHeader:(NSData*)nalu;
@end
