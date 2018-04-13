//
//  MatchDirectorViewController.h
//  sportdream
//
//  Created by lili on 2017/12/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h" // for TCP
#import "GCDAsyncUdpSocket.h" // for UDP

@interface MatchDirectorViewController : UIViewController < GCDAsyncUdpSocketDelegate,GCDAsyncSocketDelegate,UITableViewDelegate,UITableViewDataSource>

@end
