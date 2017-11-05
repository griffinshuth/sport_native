//
//  MultipeerAdvertiserModule.m
//  sportdream
//
//  Created by lili on 2017/10/19.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "MultipeerAdvertiserModule.h"

@implementation MultipeerAdvertiserModule
RCT_EXPORT_MODULE(MultipeerAdvertiserModule);
- (id) init
{
  self = [super init];
  if(!self) return nil;
  flag = 11;
  MCPeerID* peerID = [[MCPeerID alloc] initWithDisplayName:@"mangguo"];
  _session = [[MCSession alloc] initWithPeer:peerID];
  _session.delegate = self;
  _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"cmj-stream" discoveryInfo:nil session:_session];
  _advertiserAssistant.delegate = self;
  return self;
}

#pragma mark - MCSession代理方法
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
  NSLog(@"didChangeState");
  switch(state){
    case MCSessionStateConnected:
      NSLog(@"连接成功.");
      break;
    case MCSessionStateConnecting:
      NSLog(@"正在连接...");
      break;
    default:
      NSLog(@"连接失败.");
      break;
  }
}

RCT_EXPORT_METHOD(testInit:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
  NSNumber *myNumber = [NSNumber numberWithInt:flag];
  [result setObject:myNumber forKey:@"flag"];
  resolve(result);
}

RCT_EXPORT_METHOD(advertise)
{
  [self.advertiserAssistant start];
}

RCT_EXPORT_METHOD(sendData:(NSString*)data resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSError* error = nil;
  [self.session sendData:[data dataUsingEncoding:NSUTF8StringEncoding] toPeers:[self.session connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
  NSLog(@"开始发送数据...");
  if (error) {
    NSLog(@"发送数据过程中发生错误，错误信息：%@",error.localizedDescription);
  }
}

@end
