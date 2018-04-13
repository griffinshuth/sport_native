//
//  ChatMessageContainerViewController.h
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EaseUI.h"

@interface ChatMessageContainerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationbar;
- (IBAction)goBack:(UIButton *)sender;
@property (nonatomic,strong) NSString* friendname;
@property (nonatomic) EMConversationType conversationType;
@property (nonatomic,strong) EaseMessageViewController* easeMessageViewController;


-(instancetype) initWithExtras:(NSString*)nibname friendname:(NSString*)friendname conversationType:(EMConversationType)conversationType;
@end
