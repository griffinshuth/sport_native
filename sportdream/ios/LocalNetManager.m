//
//  LocalNetManager.m
//  sportdream
//
//  Created by lili on 2018/4/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "LocalNetManager.h"
#import "PacketID.h"

//基础数据结构
@interface RemoteClient:NSObject
@property (nonatomic,strong) GCDAsyncSocket* socket;
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* deviceID;
@end

@implementation RemoteClient

@end

@implementation LocalNetManager
{
  LocalWifiNetwork* client;
  LocalWifiNetwork* server;
  NSMutableArray<RemoteClient*>*   remoteClient;
}

//delegate
-(void)serverDiscovered:(LocalWifiNetwork*)network ip:(NSString*)ip
{
  [self sendEventWithName:@"serverDiscovered" body:@{@"serverIP": ip}];
}  //client
-(void)clientSocketConnected:(LocalWifiNetwork*)network
{

}  //client
- (void)clientSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{

}  //client
-(void)clientReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data
{
  if(packetID == JSON_MESSAGE){
    NSString * json_str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      [self sendEventWithName:@"clientReceiveData" body:@{@"data":json_str}];
  }
} //client

-(void)broadcastReceived:(LocalWifiNetwork*)network ip:(NSString*)ip
{

} //server
-(void)acceptNewSocket:(LocalWifiNetwork*)network newSocket:(GCDAsyncSocket *)newSocket
{
  RemoteClient* c = [[RemoteClient alloc] init];
  c.socket = newSocket;
  [remoteClient addObject:c];
} //server
- (void)serverSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  for (int i = 0; i < [remoteClient count]; i++)
  {
    RemoteClient* t= [remoteClient objectAtIndex:i];
    if(t.socket == sock){
      NSString* d = t.deviceID;
      NSString* n = t.name;
      if(d){
        [self sendEventWithName:@"serverSocketDisconnect" body:@{@"deviceID": d,@"name":n}];
      }
      [remoteClient removeObject:t];
      break;
    }
  }
}  //server
-(void)serverReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock
{
  if(packetID == JSON_MESSAGE){
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
      NSLog(@"json解析失败：%@",err);
    }else{
      if([dic[@"id"] isEqualToString:@"login"]){
        for (int i = 0; i < [remoteClient count]; i++)
        {
          RemoteClient* t= [remoteClient objectAtIndex:i];
          if(t.socket == sock){
            t.deviceID = dic[@"deviceID"];
            t.name = dic[@"name"];
            [self sendEventWithName:@"serverReceiveData" body:@{@"deviceID": t.deviceID,@"name":t.name}];
            break;
          }
        }
      }
    }
  }
} //server

RCT_EXPORT_MODULE(LocalNetModule)

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"serverDiscovered",@"clientSocketConnected",@"clientSocketDisconnect",@"clientReceiveData"
           ,@"broadcastReceived",@"acceptNewSocket",@"serverSocketDisconnect",@"serverReceiveData"];
}

RCT_EXPORT_METHOD(startServer:(int)udpport tcpport:(int)tcpport)
{
  server = [[LocalWifiNetwork alloc] initServerWithUdpPort:udpport TcpPort:tcpport];
  server.delegate = self;
  remoteClient = [[NSMutableArray alloc] init];
}

RCT_EXPORT_METHOD(stopServer)
{
  [remoteClient removeAllObjects];
  remoteClient = nil;
  server = nil;
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

RCT_EXPORT_METHOD(clientSend:(NSString*)message)
{
  NSData *data =[message dataUsingEncoding:NSUTF8StringEncoding];
  [client clientSendPacket:JSON_MESSAGE data:data];
}

RCT_EXPORT_METHOD(serverSend:(NSString*)message deviceID:(NSString*)deviceID)
{
  for (int i = 0; i < [remoteClient count]; i++)
  {
    RemoteClient* t= [remoteClient objectAtIndex:i];
    if([t.deviceID isEqualToString:deviceID]){
      NSData *data =[message dataUsingEncoding:NSUTF8StringEncoding];
      [server serverSendPacket:JSON_MESSAGE data:data sock:t.socket];
      break;
    }
  }
}

@end
