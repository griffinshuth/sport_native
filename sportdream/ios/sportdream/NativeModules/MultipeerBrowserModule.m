//
//  MultipeerBrowserModule.m
//  sportdream
//
//  Created by lili on 2017/10/19.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "MultipeerBrowserModule.h"
#import "AppDelegate.h"

@implementation MultipeerBrowserModule
{
  bool hasListeners;
}
RCT_EXPORT_MODULE(MultipeerBrowserModule);
- (id) init
{
  self = [super init];
  if(!self) return nil;
  //创建节点
  MCPeerID *peerID=[[MCPeerID alloc]initWithDisplayName:@"KenshinCui"];
  //创建会话
  _session=[[MCSession alloc]initWithPeer:peerID];
  _session.delegate=self;
  return self;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onMultipeerDataArrived"];
}

// 在添加第一个监听函数时触发
-(void)startObserving {
  hasListeners = YES;
  // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
  hasListeners = NO;
  // Remove upstream listeners, stop unnecessary background tasks
}

#pragma mark - MCBrowserViewController代理方法
-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
  NSLog(@"已选择");
  [self.browserController dismissViewControllerAnimated:YES completion:nil];
}
-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
  NSLog(@"取消浏览.");
  [self.browserController dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - MCSession代理方法
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
  NSLog(@"didChangeState");
  switch (state) {
    case MCSessionStateConnected:
      NSLog(@"连接成功.");
      [self.browserController dismissViewControllerAnimated:YES completion:nil];
      break;
    case MCSessionStateConnecting:
      NSLog(@"正在连接...");
      break;
    default:
      NSLog(@"连接失败.");
      break;
  }
}
//接收数据
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
  NSLog(@"开始接收数据...");
  //接收文字信息
  NSLog(@"%@", [NSThread currentThread]);//(<NSThread: 0x170270540>{number = 3, name = (null)})
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *receiveData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    if (hasListeners) { // Only send events if anyone is listening
      [self sendEventWithName:@"onMultipeerDataArrived" body:@{@"data": receiveData}];
    }
  });
}

RCT_EXPORT_METHOD(browser)
{
  _browserController=[[MCBrowserViewController alloc] initWithServiceType:@"cmj-stream" session:self.session];
  _browserController.delegate = self;
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoMCBrowserViewController:_browserController];
}
@end
