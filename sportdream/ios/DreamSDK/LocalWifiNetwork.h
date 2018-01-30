//
//  LocalWifiNetwork.h
//  sportdream
//
//  Created by lili on 2017/12/26.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h" // for TCP
#import "GCDAsyncUdpSocket.h" // for UDP
#import "SocketBuffer.h"

@protocol LocalWifiNetworkDelegate <NSObject>
-(void)serverDiscovered:(NSString*)ip;  //client
-(void)broadcastReceived:(NSString*)ip; //server
-(void)acceptNewSocket:(GCDAsyncSocket *)newSocket; //server
-(void)clientSocketConnected;  //client
- (void)serverSocketDisconnect:(GCDAsyncSocket *)sock;  //server
- (void)clientSocketDisconnect:(GCDAsyncSocket *)sock;  //client
-(void)clientReceiveData:(uint16_t)packetID data:(NSData*)data; //client
-(void)serverReceiveData:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock; //server
@end

@interface LocalWifiNetwork : NSObject
@property (nonatomic, weak) id <LocalWifiNetworkDelegate> delegate;
-(id)initWithType:(BOOL)isServer;
-(void)searchDirectorServer;
-(void)clientSendPacket:(uint16_t)packetID data:(NSData*)data;
-(void)serverSendPacket:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock;
@end
