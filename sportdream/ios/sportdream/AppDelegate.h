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

- (void)goToReactNative;
- (void)goToSingleEaseChat:(NSString*)friendname;
- (void)gotoShortRecordViewController;
- (void)gotoZhiboViewController;
-(void)gotoH264ViewController;
-(void)gotoLocalNetworkViewController;
-(void)gotoMCBrowserViewController:(MCBrowserViewController*) vc;
@end
