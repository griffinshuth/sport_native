//
//  ChatMessageContainerViewController.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "ChatMessageContainerViewController.h"
#import "AppDelegate.h"

@interface ChatMessageContainerViewController ()

@end

@implementation ChatMessageContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.easeMessageViewController = [[EaseMessageViewController alloc] initWithConversationChatter:self.friendname conversationType:self.conversationType];
  CGRect containerViewFrame = self.view.frame;
  containerViewFrame.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
  self.view.frame = containerViewFrame;
  
  CGRect subframe = self.easeMessageViewController.view.frame;
  subframe.origin.y = containerViewFrame.origin.y + self.navigationbar.frame.size.height;
  subframe.size.height = containerViewFrame.size.height - subframe.origin.y;
  subframe.size.width = containerViewFrame.size.width;
  subframe.origin.x = containerViewFrame.origin.x;
  
  CGRect navframe = _navigationbar.frame;
  navframe.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
  _navigationbar.frame = navframe;
  
  self.easeMessageViewController.view.frame = subframe;
  
    [self.view insertSubview:self.easeMessageViewController.view atIndex:0];
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(instancetype) initWithExtras:(NSString*)nibname friendname:(NSString*)friendname conversationType:(EMConversationType)conversationType
{
  self = [super initWithNibName:nibname bundle:nil];
  if(self){
    self.friendname = friendname;
    self.conversationType = conversationType;
  }
  return self;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)goBack:(UIButton *)sender {
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate goToReactNative];
}
@end
