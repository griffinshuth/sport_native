//
//  ChatVideoViewLayouter.h
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VideoChatSession.h"

@interface ChatVideoViewLayouter : NSObject
-(void)layoutSessions:(NSArray<VideoChatSession*>*)sessions inContainer:(UIView*)container;
@end
