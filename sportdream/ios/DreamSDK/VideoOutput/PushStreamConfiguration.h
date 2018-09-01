//
//  PushStreamConfiguration.h
//  sportdream
//
//  Created by lili on 2018/3/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef PushStreamConfiguration_h
#define PushStreamConfiguration_h

#define kCommonCaptureSessionPreset                                 AVCaptureSessionPreset640x480
#define kHighCaptureSessionPreset                                   AVCaptureSessionPreset1280x720
#define kDesiredWidth                                               1280.0f
#define kDesiredHeight                                              720.0f
#define kFrameRate                                                  30.0f
#define kMaxVideoBitRate                                            650 * 1024
#define kAVGVideoBitRate                                            1000 * 1024
#define kAudioSampleRate                                            44100
#define kAudioChannels                                              1
#define kAudioBitRate                                               64000
#define kAudioCodecName                                             @"libfdk_aac"
//#define kAudioCodecName                                             @"libvo_aacenc"

#define WINDOW_SIZE_IN_SECS                                         3
#define NOTIFY_ENCODER_RECONFIG_INTERVAL                            15
#define PUB_BITRATE_WARNING_CNT_THRESHOLD                           10

#define LOW_QUALITY_FRAME_RATE                                      15
#define LOW_QUALITY_LIMITS_BIT_RATE                                 300 * 1024
#define LOW_QUALITY_BIT_RATE                                        280 * 1024

#define MIDDLE_QUALITY_FRAME_RATE                                   20
#define MIDDLE_QUALITY_LIMITS_BIT_RATE                              425 * 1024
#define MIDDLE_QUALITY_BIT_RATE                                     400 * 1024


#define kFakePushURL @"rtmp://pili-publish.2310live.com/grasslive/techmatch"

#endif /* PushStreamConfiguration_h */
