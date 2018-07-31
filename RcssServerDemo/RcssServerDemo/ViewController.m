//
//  ViewController.m
//  RcssServerDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import "ViewController.h"
#import "FootBallStadium.h"

@interface ViewController ()

@end

@implementation ViewController
{
    FootBallServer* server;
    FootBallStadium* court;
    UILabel* currentTimeLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    int height = self.view.frame.size.height;
    int width = self.view.frame.size.width;
    court = [[FootBallStadium alloc] init];
    court.frame = CGRectMake(0, 0, width, height);
    [self.view addSubview:court];
    server = [[FootBallServer alloc] initWithRoomId:10000];
    server.delegate = self;
    [server startServer];
    
    
    UIButton* playback = [UIButton buttonWithType:UIButtonTypeSystem];
    [playback setTitle:@"开始" forState:UIControlStateNormal];
    playback.frame = CGRectMake(160, 25, 35, 35);
    [playback addTarget:self action:@selector(playbackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playback];
    
    currentTimeLabel = [UILabel new];
    currentTimeLabel.text = @"当前时间：000000000";
    [currentTimeLabel sizeToFit];
    [self.view addSubview:currentTimeLabel];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)playbackButtonPressed:(id)sender
{
    [server kickOff];
}

-(void)StadiumUpdate:(CourtInfo*)info
{
    int time = info.time;
    NSString* timeinfo = [[NSString alloc] initWithFormat:@"当前时间：%d",time];
    currentTimeLabel.text = timeinfo;
    [court setCourtInfo:info];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
