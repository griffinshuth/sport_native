//
//  VideoPlayer.h
//  sportdream
//
//  Created by lili on 2018/4/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "FileDecoder.h"

@protocol VideoPlayerDelegate <NSObject>
- (void)didPlayAutoCompleted;
- (void)didPlayManualStop;
- (void)didVideoOutput:(CMSampleBufferRef)videoData;
-(void)filePCMDataAfterProcess:(AudioBuffer) buffer;
@end

@interface VideoPlayer : NSObject<FileDecoderDelegate>
@property (nonatomic,weak) id<VideoPlayerDelegate> delegate;
-(void)startPreview:(NSString*)filename fileExtension:(NSString*)fileExtension view:(UIView*)view;
-(void)startPush:(NSString*)filename fileExtension:(NSString*)fileExtension;
-(BOOL)isStop;
-(void)stop;
@end
