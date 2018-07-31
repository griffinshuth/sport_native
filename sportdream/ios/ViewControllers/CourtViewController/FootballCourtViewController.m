//
//  FootballCourtViewController.m
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "FootballCourtViewController.h"
#import "MyLayout.h"
#import "NerdyUI.h"

@interface FootballCourtViewController ()
@property (nonatomic,strong) FootBallStadium* containerpreview;
@end

@implementation FootballCourtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  MyFrameLayout* rootLayout = [MyFrameLayout new];
  rootLayout.backgroundColor = [UIColor whiteColor];
  self.view = rootLayout;
  self.containerpreview = [[FootBallStadium alloc] init];
  self.containerpreview.widthSize.equalTo(rootLayout.widthSize);
  self.containerpreview.heightSize.equalTo(rootLayout.heightSize);
  [rootLayout addSubview:self.containerpreview];
  UIView *backView = View.wh(40,40).bgColor(@"blue,0.7").borderRadius(20).shadow(0.8).onClick(^{
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  ImageView.img(@"btn_camera_cancel_a").embedIn(backView).centerMode;
  
  backView.myTop = 20;
  backView.myTrailing = 10;
  [rootLayout addSubview:backView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
