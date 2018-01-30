//
//  QiniuPushView.h
//  sportdream
//
//  Created by lili on 2017/12/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#import "Reachability.h"
#import <React/RCTEventDispatcher.h>

@interface QiniuPushView : UIView <PLCameraStreamingSessionDelegate,PLStreamingSendingBufferDelegate>
@property (nonatomic, strong) PLMediaStreamingSession  *session;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) NSDictionary  *profile;
@property (nonatomic, strong) NSString *rtmpURL;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;
@end
