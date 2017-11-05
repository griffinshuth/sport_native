/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTLinkingManager.h>
#import "EaseUI.h"
#import <HyphenateLite/HyphenateLite.h>
#import "ChatMessageContainerViewController.h"
//#import "BaiduMapViewManager.h"
#import "ShortvideoRecordViewController.h"
#import "ZhiboAnchorViewController.h"
#import "H264EncodeViewController.h"
#import "LocalNetworkViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
  [PLStreamingEnv initEnv];
  //[BaiduMapViewManager initSDK:@"u3e18PQCuxvarQxcGGVXj6Tz38bG9qL0"];
  EMOptions* options = [EMOptions optionsWithAppkey:@"910680459#grassroot"];
  [[EMClient sharedClient] initializeSDKWithOptions:options];
  
  NSURL *jsCodeLocation;

  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"sportdream"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  /*UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;*/
  self.reactNativeViewController = [UIViewController new];
  self.reactNativeViewController.view = rootView;
  self.window.rootViewController = self.reactNativeViewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)goToReactNative
{
  [self.window.rootViewController dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)goToSingleEaseChat:(NSString*)friendname
{
  dispatch_async(dispatch_get_main_queue(), ^{
    EaseMessageViewController* evc = [[EaseMessageViewController alloc] initWithConversationChatter:friendname conversationType:EMConversationTypeChat];

    ChatMessageContainerViewController* cvc = [[ChatMessageContainerViewController alloc] initWithExtras:@"ChatMessageContainerViewController" friendname:friendname conversationType:EMConversationTypeChat];
    UIView* containerView = cvc.view;
    CGRect containerViewFrame = containerView.frame;
    containerViewFrame.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
    containerView.frame = containerViewFrame;
    [self.window.rootViewController presentViewController:cvc animated:true completion:nil];
  });
}

- (void)gotoShortRecordViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    ShortvideoRecordViewController* shortRecord = [[ShortvideoRecordViewController alloc] init];
    [self.window.rootViewController presentViewController:shortRecord animated:true completion:nil];
  });
}

- (void)gotoZhiboViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    ZhiboAnchorViewController* zhiboViewController = [[ZhiboAnchorViewController alloc] init];
    [self.window.rootViewController presentViewController:zhiboViewController animated:true completion:nil];
  });
}

-(void)gotoH264ViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    H264EncodeViewController* h264ViewController = [[H264EncodeViewController alloc] init];
    [self.window.rootViewController presentViewController:h264ViewController animated:true completion:nil];
  });
}

-(void)gotoLocalNetworkViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    LocalNetworkViewController* localNetworkViewController = [[LocalNetworkViewController alloc] init];
    [self.window.rootViewController presentViewController:localNetworkViewController animated:true completion:nil];
  });
}

-(void)gotoMCBrowserViewController:(MCBrowserViewController*) vc
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.window.rootViewController presentViewController:vc animated:true completion:nil];
  });
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  return [RCTLinkingManager application:application openURL:url
                      sourceApplication:sourceApplication annotation:annotation];
}

// APP进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [[EMClient sharedClient] applicationDidEnterBackground:application];
}

// APP将要从后台返回
- (void)applicationWillEnterForeground:(UIApplication *)application
{
  [[EMClient sharedClient] applicationWillEnterForeground:application];
}

@end
