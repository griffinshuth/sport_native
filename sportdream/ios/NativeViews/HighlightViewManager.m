//
//  HighlightViewManager.m
//  sportdream
//
//  Created by lili on 2018/5/23.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "HighlightViewManager.h"
#import "CameraStandView.h"

@implementation HighlightViewManager
{
  CameraStandView* preview;
  LocalWifiNetwork* server;
  NSMutableArray<LocalRemoteClientStruct*>* remoteClient;
}
RCT_EXPORT_MODULE();

RCT_EXPORT_VIEW_PROPERTY(uid, NSNumber)

-(id)init
{
  self = [super init];
  if(self){
    
  }
  return self;
}

-(void)dealloc
{
  
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
      NSString* n = t.name;
      if(d){
        [self.bridge.eventDispatcher sendAppEventWithName:@"onHighlightServerRemoteClientClosed" body:@{@"deviceID":t.deviceID}];
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
              t.name = dic[@"name"];
              [self.bridge.eventDispatcher sendAppEventWithName:@"onHighlightServerRemoteClientLogined" body:@{@"deviceID":t.deviceID}];
          }else{
            //json协议
            NSString* json_str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self.bridge.eventDispatcher sendAppEventWithName:@"onHighlightServerDataReceived" body:@{@"deviceID":t.deviceID,@"json_str":json_str}];
          }
        }
      }else if(packetID == SEND_SMALL_H264SDATA){
        [preview.decoder decodeH264WithoutHeader:data];
      }
      break;
    }
  }
} //server


-(UIView*)view
{
  CameraStandView* v = [[CameraStandView alloc] init];
  preview = v;
  return v;
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
  preview = nil;
}

RCT_EXPORT_METHOD(send:(NSString*)deviceID message:(NSString*)message)
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
