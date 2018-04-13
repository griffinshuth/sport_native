//
//  LocalNetManager.h
//  sportdream
//
//  Created by lili on 2018/4/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "LocalWifiNetwork.h"

@interface LocalNetManager : RCTEventEmitter <RCTBridgeModule,LocalWifiNetworkDelegate>

@end
