//
//  MultipeerBrowserModule.h
//  sportdream
//
//  Created by lili on 2017/10/19.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MultipeerBrowserModule :RCTEventEmitter <RCTBridgeModule,MCSessionDelegate,MCBrowserViewControllerDelegate>
@property (strong,nonatomic) MCSession* session;
@property (strong,nonatomic) MCBrowserViewController* browserController;
@end
