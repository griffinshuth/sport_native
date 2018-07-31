//
//  ViewController.m
//  FootballAgentDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import "ViewController.h"
#import "FootballRobots.h"

@interface ViewController ()

@end

@implementation ViewController
{
    FootballRobots* team;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    team = [[FootballRobots alloc] initWithUserId:10000 roomid:10000];
    [team startMatch];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
