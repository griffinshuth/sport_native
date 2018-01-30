//
//  QiniuPlayerViewController.h
//  sportdream
//
//  Created by lili on 2017/12/13.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLPlayerKit/PLPlayerKit.h>

@interface QiniuPlayerViewController : UIViewController <PLPlayerDelegate>
@property (nonatomic,strong) PLPlayer *player;
@property (nonatomic,strong) NSString *url;
@end
