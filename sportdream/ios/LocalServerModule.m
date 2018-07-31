//
//  LocalServerModule.m
//  sportdream
//
//  Created by lili on 2018/5/14.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "LocalServerModule.h"
#import "PacketID.h"
#import "LocalRemoteClientStruct.h"


@implementation LocalServerModule
{
  LocalWifiNetwork* server;
  NSMutableArray<LocalRemoteClientStruct*>*   remoteClient;
}

//delegate
-(void)broadcastReceived:(LocalWifiNetwork*)network ip:(NSString*)ip
{
  
} //server
-(void)acceptNewSocket:(LocalWifiNetwork*)network newSocket:(GCDAsyncSocket *)newSocket
{
  LocalRemoteClientStruct* c = [[LocalRemoteClientStruct alloc] init];
  c.socket = newSocket;
  [remoteClient addObject:c];
} //server
- (void)serverSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  for (int i = 0; i < [remoteClient count]; i++)
  {
    LocalRemoteClientStruct* t= [remoteClient objectAtIndex:i];
    if(t.socket == sock){
      NSString* d = t.deviceID;
      if(d){
        [self sendEventWithName:@"remoteSocketDisconnect" body:@{@"deviceID": d}];
      }
      [remoteClient removeObject:t];
      break;
    }
  }
}  //server
-(void)serverReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock
{
  for (int i = 0; i < [remoteClient count]; i++)
  {
    LocalRemoteClientStruct* t= [remoteClient objectAtIndex:i];
    if(t.socket == sock){
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
            t.deviceID = dic[@"deviceID"];
            [self sendEventWithName:@"onRemoteClientLogined" body:@{@"deviceID": t.deviceID}];
          }else{
            NSString* json_str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self sendEventWithName:@"serverReceiveData" body:@{@"deviceID":t.deviceID,@"json_str":json_str}];
          }
        }
      }
      break;
    }
  }
} //server

RCT_EXPORT_MODULE(LocalServerModule)

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onRemoteClientLogined",@"remoteSocketDisconnect",@"serverReceiveData"];
}

RCT_EXPORT_METHOD(startServer:(NSString*)ip udpport:(int)udpport tcpport:(int)tcpport)
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

RCT_EXPORT_METHOD(serverSend:(NSString*)message deviceID:(NSString*)deviceID)
{
  for (int i = 0; i < [remoteClient count]; i++)
  {
    LocalRemoteClientStruct* t= [remoteClient objectAtIndex:i];
    if([t.deviceID isEqualToString:deviceID]){
      NSData *data =[message dataUsingEncoding:NSUTF8StringEncoding];
      [server serverSendPacket:JSON_MESSAGE data:data sock:t.socket];
      break;
    }
  }
}

@end

