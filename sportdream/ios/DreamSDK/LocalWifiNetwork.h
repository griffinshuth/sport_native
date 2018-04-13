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
@class LocalWifiNetwork;

@protocol LocalWifiNetworkDelegate <NSObject>
-(void)serverDiscovered:(LocalWifiNetwork*)network ip:(NSString*)ip;  //client
-(void)clientSocketConnected:(LocalWifiNetwork*)network;  //client
- (void)clientSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock;  //client
-(void)clientReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data; //client

-(void)broadcastReceived:(LocalWifiNetwork*)network ip:(NSString*)ip; //server
-(void)acceptNewSocket:(LocalWifiNetwork*)network newSocket:(GCDAsyncSocket *)newSocket; //server
- (void)serverSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock;  //server
-(void)serverReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock; //server
@end

@interface LocalWifiNetwork : NSObject
@property (nonatomic, weak) id <LocalWifiNetworkDelegate> delegate;
-(id)initWithType:(BOOL)isServer;
-(id)initServerWithUdpPort:(int)udp TcpPort:(int)tcp;
-(id)initClientWithUdpPort:(int)udp TcpPort:(int)tcp;
-(void)searchServer;
-(void)searchDirectorServer;
-(void)clientSendPacket:(uint16_t)packetID data:(NSData*)data;
-(void)serverSendPacket:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock;
@end
