//
//  LocalClientModule.m
//  sportdream
//
//  Created by lili on 2018/5/14.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "LocalClientModule.h"
#import "PacketID.h"

@implementation LocalClientModule
{
  LocalWifiNetwork* client;
}

//delegate
-(void)serverDiscovered:(LocalWifiNetwork*)network ip:(NSString*)ip
{
  [self sendEventWithName:@"serverDiscovered" body:@{@"serverIP": ip}];
}  //client
-(void)clientSocketConnected:(LocalWifiNetwork*)network
{
  [self sendEventWithName:@"clientSocketConnected" body:@{}];
}  //client
- (void)clientSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  [self sendEventWithName:@"clientSocketDisconnect" body:@{}];
}  //client
-(void)clientReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data
{
  if(packetID == JSON_MESSAGE){
    NSString * json_str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self sendEventWithName:@"clientReceiveData" body:@{@"data":json_str}];
  }
} //client



RCT_EXPORT_MODULE(LocalClientModule)

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onSearchServerTimeout",@"serverDiscovered",@"clientSocketConnected",@"clientSocketDisconnect",@"clientReceiveData"];
}

RCT_EXPORT_METHOD(startClient:(int)udpport tcpport:(int)tcpport)
{
  client = [[LocalWifiNetwork alloc] initClientWithUdpPort:udpport TcpPort:tcpport];
  client.delegate = self;
}

RCT_EXPORT_METHOD(stopClient)
{
  client = nil;
}

RCT_EXPORT_METHOD(searchServer)
{
  [client searchServer];
}

RCT_EXPORT_METHOD(commonLogin:(NSString*)deviceID)
{
  NSDictionary* dict = @{
                         @"id": @"login",
                         @"deviceID":deviceID
                         };
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
  [client clientSendPacket:JSON_MESSAGE data:jsonData];
}

RCT_EXPORT_METHOD(connectServer:(NSString*)ip)
{
  [client connectServerByIP:ip];
}

RCT_EXPORT_METHOD(clientSend:(NSString*)message)
{
  NSData *data =[message dataUsingEncoding:NSUTF8StringEncoding];
  [client clientSendPacket:JSON_MESSAGE data:data];
}

@end

