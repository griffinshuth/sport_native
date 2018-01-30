//
//  H264EncodeViewController.h
//  sportdream
//
//  Created by lili on 2017/10/1.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h" // for TCP
#import "GCDAsyncUdpSocket.h" // for UDP

@interface H264EncodeViewController : UIViewController <GCDAsyncUdpSocketDelegate>
@property (nonatomic,strong) NSString* rtmpUrl;
@end
