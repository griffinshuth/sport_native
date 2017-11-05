//
//  EaseMessageView.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "EaseMessageView.h"

@implementation EaseMessageView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)init
{
  if(self = [super init])
  {
    UILabel* title = ({
      UILabel* label = [[UILabel alloc] init];
      label.frame = CGRectMake(100, 100, 100, 100);
      label.text = @"我的原生UI";
      label.textColor = [UIColor blackColor];
      label.backgroundColor = [UIColor redColor];
      label;
    });
    [self addSubview:title];
  }
  return self;
}

@end
