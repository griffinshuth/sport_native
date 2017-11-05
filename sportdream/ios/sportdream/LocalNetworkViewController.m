//
//  LocalNetworkViewController.m
//  sportdream
//
//  Created by lili on 2017/10/7.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "LocalNetworkViewController.h"

@interface LocalNetworkViewController ()

@end

@implementation LocalNetworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

- (IBAction)back:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openWifi:(UIButton *)sender {
    //NSURL *url = [NSURL URLWithString:@"prefs:root=WIFI"];
    //NSURL *url = [NSURL URLWithString:@"prefs:root=Bluetooth"];
    NSURL *url = [NSURL URLWithString:@"prefs:root=INTERNET_TETHERING"];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}
@end
