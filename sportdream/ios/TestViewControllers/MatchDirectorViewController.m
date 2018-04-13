//
//  MatchDirectorViewController.m
//  sportdream
//
//  Created by lili on 2017/12/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "MatchDirectorViewController.h"
#import "MBProgressHUD.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AAPLEAGLLayer.h"
#import "SocketClient.h"
#import "NerdyUI.h"
#import "MyLayout.h"
#import "CFTool.h"

@interface MatchDirectorViewController ()
@property (nonatomic,strong) GCDAsyncUdpSocket* broadcastSocketOfSend;
@property (nonatomic,strong) GCDAsyncUdpSocket* broadcastSocketOfReceive;
@property (nonatomic,strong) GCDAsyncUdpSocket* videoDataSocketOfReceive;
@property (strong,nonatomic) UIView* playView;
@property (strong,nonatomic)  GCDAsyncSocket *listenSocket;
@property (strong,nonatomic) GCDAsyncSocket *androidTcpSocket;
@property (strong,nonatomic)  UITableView* CaremasView;
@property (strong,nonatomic) NSIndexPath* selectCamera;
@end

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
  
  CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
  *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@implementation MatchDirectorViewController
{
  MBProgressHUD *HUD;
  NSString* localIP;
  NSString* serverIP;
  
  uint8_t* _sps;
  NSInteger _spsSize;
  uint8_t* _pps;
  NSInteger _ppsSize;
  VTDecompressionSessionRef _decoderSession;
  CMVideoFormatDescriptionRef _decoderFormatDescription;
  AAPLEAGLLayer* _glLayer;
  dispatch_queue_t _decodeQueue;
  
  dispatch_queue_t socketQueue;
  NSMutableArray *connectedSockets;
}
-(id)init
{
  self = [super init];
  if(self)
  {
    self.broadcastSocketOfSend = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError * error = nil;
    //[self.broadcastSocketOfSend bindToPort:8888 error:&error];
    if (error) {
      NSLog(@"error:%@",error);
    }else {
      [self.broadcastSocketOfSend enableBroadcast:YES error:&error];
      if (error) {
        NSLog(@"error:%@",error);
      }
    }
    
    self.broadcastSocketOfReceive = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.broadcastSocketOfReceive bindToPort:8888 error:&error];
    if (error) {
      NSLog(@"error:%@",error);
    }else {
      [self.broadcastSocketOfReceive beginReceiving:&error];// 一直接收
      // [self.broadcastSocketOfReceive receiveOnce:&error]; (只接收一次)
      
    }
    
    self.videoDataSocketOfReceive = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.videoDataSocketOfReceive bindToPort:9888 error:nil];
    [self.videoDataSocketOfReceive beginReceiving:nil];
    
    _decodeQueue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
    
    self.selectCamera = nil;
    
  }
  return self;
}

-(void)dealloc
{
  [self.broadcastSocketOfReceive close];
  [self.videoDataSocketOfReceive close];
  [self destroyTcpSocket];
}

-(void)initTcpSocket
{
  socketQueue = dispatch_queue_create("socketQueue", NULL);
  self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
  // Setup an array to store all accepted client connections
  connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
  NSError *error = nil;
  if(![self.listenSocket acceptOnPort:6666 error:&error])
  {
    NSLog(@"Error starting server: %@", error);
  }
  
  dispatch_queue_t mainQueue = dispatch_get_main_queue();
  self.androidTcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
}

-(void)destroyTcpSocket
{
  // Stop accepting connections
  [self.listenSocket disconnect];
  
  // Stop any client connections
  @synchronized(connectedSockets)
  {
    NSUInteger i;
    for (i = 0; i < [connectedSockets count]; i++)
    {
      // Call disconnect on the socket,
      // which will invoke the socketDidDisconnect: method,
      // which will remove the socket from the list.
      SocketClient* t= [connectedSockets objectAtIndex:i];
      [t.socket disconnect];
    }
  }
}

-(bool)initH264Decoder{
  if(_decoderSession){
    return YES;
  }
  const uint8_t* const parameterSetPointers[2] = {_sps,_pps};
  const size_t parameterSetSizes[2] = {_spsSize,_ppsSize};
  OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_decoderFormatDescription);
  if(status == noErr){
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decoderFormatDescription, NULL, attrs, &callBackRecord, &_decoderSession);
    CFRelease(attrs);
  }else{
    NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
  }
  return YES;
}

-(void)clearH264Decoder{
  if(_decoderSession){
    VTDecompressionSessionInvalidate(_decoderSession);
    CFRelease(_decoderSession);
    _decoderSession = NULL;
  }
  if(_decoderFormatDescription){
    CFRelease(_decoderFormatDescription);
    _decoderFormatDescription = NULL;
  }
  free(_sps);
  free(_pps);
  _spsSize = _ppsSize = 0;
}

-(CVPixelBufferRef)decode:(Byte*)buffer size:(size_t)size{
  CVPixelBufferRef outputPixelBuffer = NULL;
  CMBlockBufferRef blockBuffer = NULL;
  OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)buffer, size, kCFAllocatorNull, NULL, 0, size, 0, &blockBuffer);
  if(status == kCMBlockBufferNoErr){
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {size};
    status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decoderFormatDescription, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
    if(status == kCMBlockBufferNoErr && sampleBuffer){
      VTDecodeFrameFlags flags = 0;
      VTDecodeInfoFlags flagOut = 0;
      OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decoderSession, sampleBuffer, flags, &outputPixelBuffer, &flagOut);
      if(decodeStatus == kVTInvalidSessionErr) {
        NSLog(@"IOS8VT: Invalid session, reset decoder session");
      } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
        NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
      } else if(decodeStatus != noErr) {
        NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
      }
      CFRelease(sampleBuffer);
    }
    CFRelease(blockBuffer);
  }
  
  return outputPixelBuffer;
}


-(void)decodeH264:(NSData*)nalu
{
  size_t size = [nalu length];
  Byte* buffer = malloc(size);
  [nalu getBytes:buffer length:size];
  dispatch_async(_decodeQueue,^{
    uint32_t nalSize = (uint32_t)(size - 4);
    uint32_t big_nalSize = CFSwapInt32HostToBig(nalSize);
    uint8_t *pNalSize = (uint8_t*)(&big_nalSize);
    buffer[0] = *(pNalSize);
    buffer[1] = *(pNalSize + 1);
    buffer[2] = *(pNalSize + 2);
    buffer[3] = *(pNalSize + 3);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = buffer[4] & 0x1F;
    switch (nalType) {
      case 0x05:
        NSLog(@"Nal type is IDR frame");
        if([self initH264Decoder]) {
          pixelBuffer = [self decode:buffer size:size];
        }
        break;
      case 0x07:
        NSLog(@"Nal type is SPS");
        _spsSize = size - 4;
        _sps = malloc(_spsSize);
        memcpy(_sps, buffer + 4, _spsSize);
        break;
      case 0x08:
        NSLog(@"Nal type is PPS");
        _ppsSize = size - 4;
        _pps = malloc(_ppsSize);
        memcpy(_pps, buffer + 4, _ppsSize);
        break;
        
      default:
        NSLog(@"Nal type is B/P frame");
        pixelBuffer = [self decode:buffer size:size];
        break;
    }
    
    if(pixelBuffer) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        _glLayer.pixelBuffer = pixelBuffer;
      });
      
      CVPixelBufferRelease(pixelBuffer);
    }
    
    free(buffer);
  });
}

-(UILabel*)createSectionLabel:(NSString*)title
{
  UILabel *sectionLabel = [UILabel new];
  sectionLabel.text = title;
  sectionLabel.font = [CFTool font:17];
  [sectionLabel sizeToFit];             //sizeToFit函数的意思是让视图的尺寸刚好包裹其内容。注意sizeToFit方法必要在设置字体、文字后调用才正确。
  return sectionLabel;
}

-(UILabel*)createLabel:(NSString*)title backgroundColor:(UIColor*)color
{
  UILabel *v = [UILabel new];
  v.text = title;
  v.font = [CFTool font:15];
  v.numberOfLines = 0;
  v.textAlignment = NSTextAlignmentCenter;
  v.adjustsFontSizeToFitWidth = YES;
  v.backgroundColor =  color;
  v.layer.shadowOffset = CGSizeMake(3, 3);
  v.layer.shadowColor = [CFTool color:4].CGColor;
  v.layer.shadowRadius = 2;
  v.layer.shadowOpacity = 0.3;
  
  return v;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  MyLinearLayout *rootLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  rootLayout.backgroundColor = [UIColor whiteColor];
  self.view = rootLayout;
    // Do any additional setup after loading the view from its nib.
  CGFloat screen_width = CGRectGetWidth([UIScreen mainScreen].bounds);

  UIView *view1 = View.wh(screen_width, 50).bgColor(@"red").opacity(0.7).border(3, @"3d3d3d");
  self.view.addChild(view1);
  view1.topPos.equalTo(self.topLayoutGuide).offset(10);
  UIButton    *_actionButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [self clearH264Decoder];
    [self dismissViewControllerAnimated:YES completion:nil];
  });;
  _actionButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  _actionButton.str(@"BACK");
  UILabel     *_iapLabel = Label.fnt(9).color(@"darkGray").lines(2).str(@"导播系统").centerAlignment;
  HorStack(
           _actionButton,
           @10,
           _iapLabel,
           ).embedIn(view1, 10, 10, 10, 15);

  self.playView = [UIView new];
  self.playView.myTop = 0;
  self.playView.myLeading = 0;
  self.playView.myWidth = screen_width;
  self.playView.myHeight = 200;
  self.playView.backgroundColor = [UIColor redColor];
  [rootLayout addSubview:self.playView];
  _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, screen_width, 200)];
  [self.playView.layer addSublayer:_glLayer];
  
  //UITableView
  self.CaremasView = [[UITableView alloc] init];
  self.CaremasView.myTop = 10;
  self.CaremasView.myWidth = screen_width;
  self.CaremasView.myHeight = 100;
  self.CaremasView.delegate = self;
  self.CaremasView.dataSource = self;
  [rootLayout addSubview:self.CaremasView];
  
  id title = AttStr(@"停止广播").fnt(15).underline.range(0, 3).fnt(@18).color(@"#0065F7");
  UIButton *button1 = Button.str(title).insets(5, 10).fitSize.border(1).onClick(^(UIButton *btn) {
    
  });
  [rootLayout addSubview:button1];
  [self initTcpSocket];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSUInteger count = [connectedSockets count];
  if(count == 0){
    return 1;
  }else{
    return count;
  }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if([connectedSockets count] == 0){
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"empty"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"没有摄像头";
    return cell;
  }
  static NSString* tableId = @"tableIP";
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:tableId];
  if(cell == nil){
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableId];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  SocketClient* c = [connectedSockets objectAtIndex:indexPath.row];
  cell.textLabel.text = [c.socket connectedHost];
  if(indexPath == self.selectCamera){
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }else{
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if([connectedSockets count] == 0){
    Alert.title(@"Alert").message(@"没有摄像头可以使用").action(@"OK", ^{
      Log(@"OK");
    }).cancelAction(@"Cancel").show();
    return;
  }
  [self showAlert:indexPath];
}

- (void)showAlert:(NSIndexPath *)indexPath {
  long newRow = [indexPath row];
  long oldRow = self.selectCamera?[self.selectCamera row]:-1;
  if(newRow != oldRow){
    SocketClient* c = [connectedSockets objectAtIndex:indexPath.row];
    NSString* ip = [c.socket connectedHost];
    NSString* message = [[NSString alloc] initWithFormat:@"是否使用摄像头%@进行直播？",ip];
    Alert.title(@"摄像头").message(message).action(@"使用", ^{
      UITableViewCell *newCell = [self.CaremasView cellForRowAtIndexPath:indexPath];
      newCell.accessoryType = UITableViewCellAccessoryCheckmark;
      UITableViewCell *oldCell = [self.CaremasView cellForRowAtIndexPath:self.selectCamera];
      oldCell.accessoryType = UITableViewCellAccessoryNone;
      self.selectCamera = [indexPath copy];
    }).cancelAction(@"取消").show();
  }
}

-(void)backButtonEvent:(id)sender
{
  [self clearH264Decoder];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// 发送UDP
-(void)sendBroadcastUDPData:(NSString *)str
{
  NSLog(@"to ddc : %@",str);
  NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
  [self.broadcastSocketOfSend sendData:data toHost:@"255.255.255.255" port:8888 withTimeout:-1 tag:0];   // 注意：这里的发送也是异步的,"255.255.255.255",是组播方式,withTimeout设置成-1代表超时时间为-1，即永不超时；
}

-(void)sendUDPData:(NSString*)str ip:(NSString*)ip
{
  NSLog(@"to ddc : %@",str);
  NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
  [self.broadcastSocketOfSend sendData:data toHost:ip port:8888 withTimeout:-1 tag:0];   // 注意：这里的发送也是异步的,"255.255.255.255",是组播方式,withTimeout设置成-1代表超时时间为-1，即永不超时；

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
  if(sock == self.videoDataSocketOfReceive){
    [self decodeH264:data];
  }else if(sock == self.broadcastSocketOfReceive){
    if([GCDAsyncSocket isIPv6Address:address]){
      return;
    }
    NSString *aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString * ip = [GCDAsyncUdpSocket hostFromAddress:address];
    NSString *deviceUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"接收到消息: %@,%@",aStr,ip);
    if([aStr containsString:@"hand"]){
      if([aStr containsString:deviceUUID]){
        localIP = [[NSString alloc] initWithFormat:@"%@",ip];
      }else{
        [self sendUDPData:@"echo" ip:ip];
      }
    }else if([aStr isEqualToString:@"androidbroadcast"]){
      //[self Toast:ip];
      NSError *error = nil;
      if ([self.androidTcpSocket connectToHost:ip onPort:3333 error:&error])
      {
        NSLog(@"Error connecting: %@", error);
      }
    }else if([aStr isEqualToString:@"androidtest"]){
      [self Toast:aStr];
    }else{
      NSLog(@"%@",aStr);
    }
  }
}

//TCP
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
  
}
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
  // This method is executed on the socketQueue (not the main thread)
  @synchronized(connectedSockets)
  {
    SocketClient* client = [[SocketClient alloc] init];
    client.socket = newSocket;
    [connectedSockets addObject:client];
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.CaremasView reloadData];
  });
  newSocket.delegate = self;
  NSString *welcomeMsg = @"Welcome";
  NSData *info =[welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
  uint32_t len = (uint32_t)[info length];
  uint16_t packetID = 1;
  NSData* sendPacket = [SocketClient createPacket:len ID:packetID bytes:[info bytes]];
  [newSocket readDataWithTimeout:-1 tag:0];
  [newSocket writeData:sendPacket withTimeout:-1 tag:0];
  
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
  NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //NSString *aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //[self Toast:aStr];
  SocketClient* client = [self getClientFromSocket:sock];
  [client addData:data];
  PacketInfo* packet = [client nextPacket:nil];
  PacketInfo* last  = nil;
  while(packet){
    //开始处理包
    uint32_t len = packet.len;
    uint16_t ID = packet.packetID;
    uint8_t* content = packet.data;
    NSLog(@"packet length:%d",len);
    NSLog(@"packet ID:%d",ID);
    if(ID == 1){
      NSData *contentData = [[NSData alloc] initWithBytes:content length:len];
      NSString *aStr = [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
      [self Toast:aStr];
    }else if(ID == 9999){
      NSData* h264Packet = [[NSData alloc] initWithBytes:content length:len];
      [self decodeH264:h264Packet];
    }
    //处理完毕
    last = packet;
    packet = [client nextPacket:last];
  }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
  
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
  if (sock != self.listenSocket)
  {
    @synchronized(connectedSockets)
    {
      //[connectedSockets removeObject:sock];
      for(SocketClient* obj in connectedSockets){
        if(obj.socket == sock){
          [connectedSockets removeObject:obj];
          dispatch_async(dispatch_get_main_queue(), ^{
            [self.CaremasView reloadData];
          });
          NSLog(@"remove from connectedSockets:num:%zd",[connectedSockets count]);
          return;
        }
      }
    }
  }
}

-(SocketClient*)getClientFromSocket:(GCDAsyncSocket *)sock
{
  for(SocketClient* obj in connectedSockets){
    if(obj.socket == sock){
      return obj;
    }
  }
  return nil;
}

-(void) Toast:(NSString*)str
{
  dispatch_async(dispatch_get_main_queue(), ^(){
    //初始化进度框，置于当前的View当中
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    //如果设置此属性则当前的view置于后台
    HUD.dimBackground = NO;
    
    //设置对话框文字
    HUD.labelText = str;
    
    //显示对话框
    [HUD showAnimated:YES whileExecutingBlock:^{
      //对话框显示时需要执行的操作
      sleep(1);
    } completionBlock:^{
      //操作执行完后取消对话框
      [HUD removeFromSuperview];
      HUD = nil;
    }];
  });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
