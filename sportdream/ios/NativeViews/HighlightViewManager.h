//
//  HighlightViewManager.h
//  sportdream
//
//  Created by lili on 2018/5/23.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import "LocalWifiNetwork.h"
#import "LocalRemoteClientStruct.h"
#import "PacketID.h"

@interface HighlightViewManager : RCTViewManager<LocalWifiNetworkDelegate>

@end
