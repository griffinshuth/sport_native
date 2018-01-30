//
//  AudioRecord.h
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AudioRecordDelegate <NSObject>
-(void)captureAudioOutput:(CMSampleBufferRef)sampleBuffer;
@end

@interface AudioRecord : NSObject<AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, weak) id <AudioRecordDelegate> delegate;
-(void)startCapture;
-(void)stopCapture;
@end
