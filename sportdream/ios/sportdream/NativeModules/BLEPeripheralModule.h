//
//  BLEPeripheralModule.h
//  sportdream
//
//  Created by lili on 2018/5/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "CoreBluetooth/CoreBluetooth.h"

@interface BLEPeripheralModule : RCTEventEmitter<RCTBridgeModule,CBPeripheralManagerDelegate>

@end
