//
//  FileDecoder.h
//  sportdream
//
//  Created by lili on 2018/1/25.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol FileDecoderDelegate <NSObject>
- (void)didCompletePlayingMovie;
- (void)didVideoOutput:(CMSampleBufferRef)videoData;
- (void)didAudioOutput:(CMSampleBufferRef)audioData;
@end
@interface FileDecoder : NSObject
/** This determines whether to play back a movie as fast as the frames can be processed, or if the original speed of the movie should be respected. Defaults to NO.
 */
@property(readwrite, nonatomic) BOOL playAtActualSpeed;

/** This determines whether the video should repeat (loop) at the end and restart from the beginning. Defaults to NO.
 */
@property(readwrite, nonatomic) BOOL shouldRepeat;

@property (nonatomic, weak) id <FileDecoderDelegate> delegate;

-(id)initWithURL:(NSURL*)url;
-(id)initWithURL:(NSURL*)url withPixelType:(OSType)PixelType;
-(void)startProcessing;
-(void)cancelProcessing;
- (void)readNextVideoFrameFromOutput;
- (void)readNextAudioSampleFromOutput;
-(BOOL)isVideoFinished;
@end
