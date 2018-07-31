//
//  BasketCourtViewController.h
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasketStadium.h"
#import "MyLayout.h"
#import "NerdyUI.h"

@interface BasketCourtViewController : UIViewController
@property(nonatomic,weak) NSDictionary* gameData;
@property(nonatomic,assign) int teamindex;
@property(nonatomic,weak) NSDictionary* currentMember;
@end
