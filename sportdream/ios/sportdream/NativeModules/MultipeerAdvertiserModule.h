//
//  MultipeerAdvertiserModule.h
//  sportdream
//
//  Created by lili on 2017/10/19.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MultipeerAdvertiserModule : NSObject <RCTBridgeModule,MCAdvertiserAssistantDelegate,MCSessionDelegate>
{
  int flag;
}
@property (strong,nonatomic) MCSession* session;
@property (strong,nonatomic) MCAdvertiserAssistant* advertiserAssistant;
@end
