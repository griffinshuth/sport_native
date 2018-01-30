//
//  SocketBuffer.h
//  sportdream
//
//  Created by lili on 2017/12/26.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h" // for TCP

@interface BufferedPacketInfo : NSObject
@property (nonatomic,assign) uint32_t len;
@property (nonatomic,assign) uint16_t packetID;
@property uint8_t* data;
@end

@interface SocketBuffer : NSObject
@property GCDAsyncSocket* socket;
@property uint8_t* buffer;
@property NSInteger maxSize;
@property NSInteger currentSize;
@property NSMutableDictionary* info;

+(NSData*)createPacket:(uint32_t)len ID:(uint16_t)ID bytes:(const Byte*)bytes;
-(BOOL)addData:(NSData*)data;
-(BufferedPacketInfo*)nextPacket:(BufferedPacketInfo*)last;
@end
