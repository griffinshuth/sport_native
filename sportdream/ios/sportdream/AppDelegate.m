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
#import "ZhiboAnchorViewController.h"
#import "H264EncodeViewController.h"
#import "LocalNetworkViewController.h"
#import "VideoChatViewController.h"
#import "QiniuPlayerViewController.h"
#import "MatchDirectorViewController.h"
#import "ARCameraViewController.h"
#import "CameraOnStandViewController.h"
#import "DirectorServerViewController.h"
#import "CommentatorsViewController.h"
#import "LiveCommentatorsViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.allowRotation = FALSE;
  self.allowBothRotation = FALSE;
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

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
  if(self.allowRotation)
    return UIInterfaceOrientationMaskLandscapeLeft;
  else if(self.allowBothRotation)
    return UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskPortrait;
  else
    return UIInterfaceOrientationMaskPortrait;
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
- (void)gotoZhiboViewController:(NSString*)url
{
  dispatch_async(dispatch_get_main_queue(), ^{
    ZhiboAnchorViewController* zhiboViewController = [[ZhiboAnchorViewController alloc] init];
    zhiboViewController.url = url;
    [self.window.rootViewController presentViewController:zhiboViewController animated:true completion:nil];
  });
}

- (void)gotoQiniuPlayerViewController:(NSString*)url
{
  dispatch_async(dispatch_get_main_queue(), ^{
    QiniuPlayerViewController* qiniuPlayerViewController = [[QiniuPlayerViewController alloc] init];
    qiniuPlayerViewController.url = url;
    [self.window.rootViewController presentViewController:qiniuPlayerViewController animated:true completion:nil];
  });
}

-(void)gotoH264ViewController:(NSString*)url
{
  dispatch_async(dispatch_get_main_queue(), ^{
    H264EncodeViewController* h264ViewController = [[H264EncodeViewController alloc] init];
    h264ViewController.rtmpUrl = url;
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

-(void)gotoVideoChatViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    VideoChatViewController* localVideoChatViewController = [[VideoChatViewController alloc] init];
    [self.window.rootViewController presentViewController:localVideoChatViewController animated:true completion:nil];
  });
}

-(void)gotoMatchDirectorViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    MatchDirectorViewController* matchDirectorViewController = [[MatchDirectorViewController alloc] init];
    [self.window.rootViewController presentViewController:matchDirectorViewController animated:true completion:nil];
  });
}

-(void)gotoARCameraViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    ARCameraViewController* aRCameraViewController = [[ARCameraViewController alloc] init];
    [self.window.rootViewController presentViewController:aRCameraViewController animated:true completion:nil];
  });
}

-(void)gotoCameraOnStandViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    CameraOnStandViewController* cameraOnStandViewController = [[CameraOnStandViewController alloc] init];
    [self.window.rootViewController presentViewController:cameraOnStandViewController animated:true completion:nil];
  });
}

-(void)gotoDirectorServerViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    DirectorServerViewController* directorServerViewController = [[DirectorServerViewController alloc] init];
    [self.window.rootViewController presentViewController:directorServerViewController animated:true completion:nil];
  });
}

-(void)gotoCommentatorsViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    CommentatorsViewController* commentatorsViewController = [[CommentatorsViewController alloc] init];
    [self.window.rootViewController presentViewController:commentatorsViewController animated:true completion:nil];
  });
}

-(void)gotoLiveCommentatorsViewController
{
  dispatch_async(dispatch_get_main_queue(), ^{
    LiveCommentatorsViewController* liveCommentatorsViewController = [[LiveCommentatorsViewController alloc] init];
    [self.window.rootViewController presentViewController:liveCommentatorsViewController animated:true completion:nil];
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
