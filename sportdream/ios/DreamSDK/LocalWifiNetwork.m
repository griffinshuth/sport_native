//
//  LocalWifiNetwork.m
//  sportdream
//
//  Created by lili on 2017/12/26.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "LocalWifiNetwork.h"

//const int UdpPort = 8888;
//const int VideoUdpPort = 9888;
//const int TcpPort = 6666;

@interface LocalWifiNetwork() <GCDAsyncUdpSocketDelegate,GCDAsyncSocketDelegate>

@end

@implementation LocalWifiNetwork
{
  int UdpPort;
  int TcpPort;
  bool _isServer;
  NSString* serverIP;  //要连接的服务器IP，只有客户端模式有效
  GCDAsyncUdpSocket* udpSocket;//如果是客户端模式，则代表发送广播包，并接受服务器IP，如果是服务器模式，则代表接受广播包，并回应客户端
  GCDAsyncSocket *tcpSocket; //客户端模式则为发起连接的一方，服务器模式则为接受连接的一方
  //GCDAsyncUdpSocket* udpVideoSocket; //只有服务器模式使用，代表接受音视频数据
  SocketBuffer* socketBuffer; //客户端模式使用
  NSMutableArray *connectedSockets; //服务器模式使用
  GCDAsyncSocket *androidTempTcpSocket; //服务器模式使用只用于android端
}

-(id)initWithType:(BOOL)isServer
{
  self = [super init];
  if(self){
    UdpPort = 8888;
    TcpPort = 6666;
    _isServer = isServer;
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [udpSocket bindToPort:UdpPort error:nil];
    [udpSocket enableBroadcast:YES error:nil];
    [udpSocket beginReceiving:nil];// 一直接收
    
    if(_isServer){
      dispatch_queue_t socketQueue = dispatch_queue_create("serversocketQueue", NULL);
      tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
      // Setup an array to store all accepted client connections
      connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
      NSError *error = nil;
      if(![tcpSocket acceptOnPort:TcpPort error:&error])
      {
        NSLog(@"Error starting server: %@", error);
      }
      
      dispatch_queue_t androidTempTcpSocketQueue = dispatch_queue_create("androidTempTcpSocketQueue", NULL);
      androidTempTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:androidTempTcpSocketQueue];
    }else{
      dispatch_queue_t socketQueue = dispatch_queue_create("socketQueue", NULL);
      tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    }
  }
  return self;
}

-(id)initServerWithUdpPort:(int)udp TcpPort:(int)tcp
{
  self = [super self];
  if(self){
    UdpPort = udp;
    TcpPort = tcp;
    _isServer = true;
    
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [udpSocket bindToPort:UdpPort error:nil];
    [udpSocket enableBroadcast:YES error:nil];
    [udpSocket beginReceiving:nil];// 一直接收
    
    dispatch_queue_t socketQueue = dispatch_queue_create("serversocketQueue", NULL);
    tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    NSError *error = nil;
    if(![tcpSocket acceptOnPort:TcpPort error:&error])
    {
      NSLog(@"Error starting server: %@", error);
    }
    
    dispatch_queue_t androidTempTcpSocketQueue = dispatch_queue_create("androidTempTcpSocketQueue", NULL);
    androidTempTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:androidTempTcpSocketQueue];
  }
  return self;
}

-(id)initClientWithUdpPort:(int)udp TcpPort:(int)tcp
{
  self = [super self];
  if(self){
    UdpPort = udp;
    TcpPort = tcp;
    _isServer = false;
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [udpSocket bindToPort:UdpPort error:nil];
    [udpSocket enableBroadcast:YES error:nil];
    [udpSocket beginReceiving:nil];// 一直接收
    
    dispatch_queue_t socketQueue = dispatch_queue_create("socketQueue", NULL);
    tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
  }
  return self;
}

-(void)dealloc
{
  [udpSocket close];
  if(_isServer){
    // Stop accepting connections
    [tcpSocket disconnect];
    
    // Stop any client connections
    @synchronized(connectedSockets)
    {
      NSUInteger i;
      for (i = 0; i < [connectedSockets count]; i++)
      {
        // Call disconnect on the socket,
        // which will invoke the socketDidDisconnect: method,
        // which will remove the socket from the list.
        SocketBuffer* t= [connectedSockets objectAtIndex:i];
        [t.socket disconnect];
      }
    }
  }else{
    [tcpSocket disconnect];
  }
}

-(void)searchDirectorServer
{
  if(!_isServer){
    //发送广播信息，寻找服务器IP地址
    [self sendUDPData:@"hand" ip:@"255.255.255.255" port:UdpPort];
  }
}

-(void)searchServer
{
  if(!_isServer){
    //发送广播信息，寻找服务器IP地址
    [self sendUDPData:@"hand" ip:@"255.255.255.255" port:UdpPort];
  }
}

-(void)sendUDPData:(NSString*)str ip:(NSString*)ip port:(int)port
{
  NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
  [udpSocket sendData:data toHost:ip port:port withTimeout:-1 tag:0];   // 注意：这里的发送也是异步的,withTimeout设置成-1代表超时时间为-1，即永不超时；
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
  NSLog(@"发送信息成功");
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
  NSLog(@"发送信息失败");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
  if([GCDAsyncSocket isIPv6Address:address]){
    return;
  }
  NSString *aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSString * ip = [GCDAsyncUdpSocket hostFromAddress:address];
  uint16_t port = [GCDAsyncSocket portFromAddress:address];
  if(_isServer){
    //处理寻找服务器的广播
    if([aStr isEqualToString:@"hand"]){
      [self sendUDPData:@"echo" ip:ip port:port];
      [self.delegate broadcastReceived:self ip:ip];
    }else if([aStr isEqualToString:@"androidbroadcast"]){
      NSError *error = nil;
      if ([androidTempTcpSocket connectToHost:ip onPort:3333 error:&error])
      {
        NSLog(@"Error connecting: %@", error);
      }
    }
  }else{
    if([aStr isEqualToString:@"echo"]){
      //找到服务器
      serverIP = [[NSString alloc] initWithFormat:@"%@",ip];
      NSError *error = nil;
      if (![tcpSocket connectToHost:serverIP onPort:TcpPort error:&error])
      {
        NSLog(@"Error connecting: %@", error);
      }
      [self.delegate serverDiscovered:self ip:serverIP];
    }
  }
}

-(void)clientSendPacket:(uint16_t)packetID data:(NSData*)data
{
  if(_isServer){
    return;
  }
  uint32_t len = (uint32_t)[data length];
  uint16_t ID = packetID;
  NSData* sendPacket = [SocketBuffer createPacket:len ID:ID bytes:[data bytes]];
  [tcpSocket writeData:sendPacket withTimeout:-1 tag:0];
}

-(void)serverSendPacket:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock
{
  if(!_isServer){
    return;
  }
  uint32_t len = (uint32_t)[data length];
  uint16_t ID = packetID;
  NSData* sendPacket = [SocketBuffer createPacket:len ID:ID bytes:[data bytes]];
  [sock writeData:sendPacket withTimeout:-1 tag:0];
}

//TCP
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
  if(sock == androidTempTcpSocket){
    NSLog(@"didConnectToHost");
    [androidTempTcpSocket disconnect];
  }else{
    if(!_isServer){
      [self.delegate clientSocketConnected:self];
      socketBuffer = [[SocketBuffer alloc] init];
      socketBuffer.socket = sock;
      [sock readDataWithTimeout:-1 tag:0];
    }
  }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
  NSLog(@"didAcceptNewSocket");
  @synchronized(connectedSockets)
  {
    SocketBuffer* client = [[SocketBuffer alloc] init];
    client.socket = newSocket;
    [connectedSockets addObject:client];
  }
  [newSocket readDataWithTimeout:-1 tag:0];
  [self.delegate acceptNewSocket:self newSocket:newSocket];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
  NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
  if(_isServer){
    NSData* address = [sock connectedAddress];
    if([GCDAsyncSocket isIPv6Address:address]){
      int length  = (int)data.length;
      NSLog(@"length:%d",length);
    }
    SocketBuffer* client = [self getServerClientFromSocket:sock];
    [client addData:data];
    BufferedPacketInfo* packet = [client nextPacket:nil];
    BufferedPacketInfo* last  = nil;
    while(packet){
      //开始处理包
      uint32_t len = packet.len;
      uint16_t ID = packet.packetID;
      uint8_t* content = packet.data;
      NSLog(@"packet length:%d",len);
      NSLog(@"packet ID:%d",ID);
      NSData *contentData = [[NSData alloc] initWithBytes:content length:len];
      [self.delegate serverReceiveData:self packetID:ID data:contentData sock:sock];
      //处理完毕
      last = packet;
      packet = [client nextPacket:last];
    }
  }else{
    [socketBuffer addData:data];
    BufferedPacketInfo* packet = [socketBuffer nextPacket:nil];
    BufferedPacketInfo* last  = nil;
    while(packet){
      //开始处理包
      uint32_t len = packet.len;
      uint16_t ID = packet.packetID;
      uint8_t* content = packet.data;
      NSLog(@"packet length:%d",len);
      NSLog(@"packet ID:%d",ID);
      NSData *contentData = [[NSData alloc] initWithBytes:content length:len];
      [self.delegate clientReceiveData:self packetID:ID data:contentData];
      //处理完毕
      last = packet;
      packet = [socketBuffer nextPacket:last];
    }
  }
  
  [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
  
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
  if(androidTempTcpSocket == sock){
    NSLog(@"androidTempTcpSocket socketDidDisconnect");
  }else{
    NSLog(@"otherSocket socketDidDisconnect");
    @synchronized(connectedSockets)
    {
      for(SocketBuffer* obj in connectedSockets){
        if(obj.socket == sock){
          [connectedSockets removeObject:obj];
          NSLog(@"remove from connectedSockets:num:%zd",[connectedSockets count]);
          break;
        }
      }
    }
    if(_isServer){
      if(tcpSocket != sock){
        [self.delegate serverSocketDisconnect:self sock:sock];
      }
    }else{
      [self.delegate clientSocketDisconnect:self sock:sock];
    }
  }
  
}

-(SocketBuffer*)getServerClientFromSocket:(GCDAsyncSocket *)sock
{
  for(SocketBuffer* obj in connectedSockets){
    if(obj.socket == sock){
      return obj;
    }
  }
  return nil;
}

@end





























