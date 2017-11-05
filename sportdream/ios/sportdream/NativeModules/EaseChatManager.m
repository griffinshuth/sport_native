//
//  EaseChatManager.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "EaseChatManager.h"
#import "EaseUI.h"
#import "AppDelegate.h"

@implementation EaseChatManager
RCT_EXPORT_MODULE(ChatModule);

RCT_EXPORT_METHOD(register:(NSString*) username password:(NSString*)password nickname:(NSString*)nickname resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject )
{
  EMError* error = [[EMClient sharedClient] registerWithUsername:username password:password];
  if(error == nil){
    resolve(@"success");
  }else{
    reject(@"1",error.errorDescription,[NSError errorWithDomain:@"错误" code:1 userInfo:nil]);
  }
}

RCT_EXPORT_METHOD(login:(NSString*)username password:(NSString*)password resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  EMError* error = [[EMClient sharedClient] loginWithUsername:username password:password];
  if(!error){
    resolve(@"success");
  }else{
    reject(@"1",error.errorDescription,[NSError errorWithDomain:@"错误" code:1 userInfo:nil]);
  }
}

RCT_EXPORT_METHOD(logout:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  EMError* error = [[EMClient sharedClient] logout:false];
  if(!error){
    resolve(@"success");
  }else{
    reject(@"1",error.errorDescription,[NSError errorWithDomain:@"错误" code:1 userInfo:nil]);
  }
}

RCT_EXPORT_METHOD(chatWithFriends:(NSString*)username)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate goToSingleEaseChat:username];
}
@end
