//
//  LocalRemoteClientStruct.h
//  sportdream
//
//  Created by lili on 2018/5/23.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface LocalRemoteClientStruct : NSObject
@property (nonatomic,strong) GCDAsyncSocket* socket;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* deviceID;
@end
