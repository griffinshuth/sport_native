//
//  BasketStadium.h
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BasketStadium : UIView
@property(nonatomic,strong) NSDictionary* gameData;
@property(nonatomic,assign) int teamindex;
@property(nonatomic,strong) NSDictionary* currentMember;
-(void)initImage;
@end
