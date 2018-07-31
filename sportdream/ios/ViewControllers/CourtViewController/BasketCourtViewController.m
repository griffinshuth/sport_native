//
//  BasketCourtViewController.m
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "BasketCourtViewController.h"
#import <Orientation.h>

@interface BasketCourtViewController ()
@property (nonatomic,strong) BasketStadium* basketCourt;
@end

@implementation BasketCourtViewController
-(id)init
{
  self = [super init];
  if(self){
    [Orientation setOrientation:UIInterfaceOrientationMaskLandscapeLeft];
  }
  return self;
}

-(void)dealloc
{
  
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  MyFrameLayout* rootLayout = [MyFrameLayout new];
  rootLayout.backgroundColor = [UIColor whiteColor];
  self.view = rootLayout;
  self.basketCourt = [[BasketStadium alloc] init];
  self.basketCourt.gameData = self.gameData;
  self.basketCourt.currentMember = self.currentMember;
  self.basketCourt.teamindex = self.teamindex;
  [self.basketCourt initImage];
  self.basketCourt.widthSize.equalTo(rootLayout.widthSize);
  self.basketCourt.heightSize.equalTo(rootLayout.heightSize);
  //self.containerpreview.myHeight = CGRectGetHeight([UIScreen mainScreen].bounds)/2;
  [rootLayout addSubview:self.basketCourt];
  UIView *backView = View.wh(30,30).bgColor(@"blue,0.7").borderRadius(15).shadow(0.8).onClick(^{
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  ImageView.img(@"btn_camera_cancel_a").embedIn(backView).centerMode;
  backView.myTop = 10;
  backView.myTrailing = 10;
  [rootLayout addSubview:backView];
  
  UIButton* playerlistButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
   
  });
  playerlistButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  playerlistButton.str(@"球员列表");
  playerlistButton.myHeight = 30;
  playerlistButton.myWidth = 100;
  playerlistButton.myTop = 10;
  playerlistButton.myLeading = 10;
  [rootLayout addSubview:playerlistButton];
  
  UIButton* sectionBeginButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  sectionBeginButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  sectionBeginButton.str(@"片段开始");
  sectionBeginButton.myHeight = 30;
  sectionBeginButton.myWidth = 100;
  sectionBeginButton.myTop = 10;
  sectionBeginButton.myLeading = 10+100+10;
  [rootLayout addSubview:sectionBeginButton];
  
  UIButton* sectionEndButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  sectionEndButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  sectionEndButton.str(@"片段结束");
  sectionEndButton.myHeight = 30;
  sectionEndButton.myWidth = 100;
  sectionEndButton.myTop = 10;
  sectionEndButton.myLeading = 10+100+10+100+10;
  [rootLayout addSubview:sectionEndButton];
  
  UIButton* saveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  saveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  saveButton.str(@"保存");
  saveButton.myHeight = 30;
  saveButton.myWidth = 60;
  saveButton.myTop = 10;
  saveButton.myLeading = 10+100+10+100+10+100+10;
  [rootLayout addSubview:saveButton];
  
  UIButton* resetButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  resetButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  resetButton.str(@"重置");
  resetButton.myHeight = 30;
  resetButton.myWidth = 60;
  resetButton.myTop = 10;
  resetButton.myLeading = 10+100+10+100+10+100+10+60+10;
  [rootLayout addSubview:resetButton];
  
  UIButton* previewButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  previewButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  previewButton.str(@"预览");
  previewButton.myHeight = 30;
  previewButton.myWidth = 60;
  previewButton.myTop = 10;
  previewButton.myLeading = 10+100+10+100+10+100+10+60+10+60+10;
  [rootLayout addSubview:previewButton];
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
