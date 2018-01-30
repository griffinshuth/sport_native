/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIViewController* reactNativeViewController;
@property (nonatomic,assign)BOOL allowRotation;
@property (nonatomic,assign)BOOL allowBothRotation;

- (void)goToReactNative;
- (void)goToSingleEaseChat:(NSString*)friendname;
- (void)gotoZhiboViewController:(NSString*)url;
- (void)gotoQiniuPlayerViewController:(NSString*)url;
-(void)gotoH264ViewController:(NSString*)url;
-(void)gotoLocalNetworkViewController;
-(void)gotoMCBrowserViewController:(MCBrowserViewController*) vc;
-(void)gotoVideoChatViewController;
-(void)gotoMatchDirectorViewController;
-(void)gotoARCameraViewController;
-(void)gotoCameraOnStandViewController;
-(void)gotoDirectorServerViewController;
-(void)gotoCommentatorsViewController;
-(void)gotoLiveCommentatorsViewController;
@end
