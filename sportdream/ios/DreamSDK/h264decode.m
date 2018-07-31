//
//  h264decode.m
//  sportdream
//
//  Created by lili on 2017/12/28.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "h264decode.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AAPLEAGLLayer.h"
#import <GPUImage/GPUImage.h>
#import "libyuv.h"
#import "BasketCourtOptions.h"
#import "Quartz2DAPI.h"

@interface decodeDataHandle:GPUImageRawDataOutput
@property (nonatomic,weak) h264decode* capture;
@end

@implementation decodeDataHandle
{
  
}
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat capture:(h264decode *)capture
{
  self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
  if (self) {
    self.capture = capture;
  }
  return self;
}
-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
  [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
  //将bgra转为yuv
  //图像宽度
  int width =imageSize.width;
  //图像高度
  int height = imageSize.height;
  //宽*高
  int w_x_h = width * height;
  //yuv数据长度 = (宽 * 高) * 3 / 2
  int yuv_len = w_x_h * 3 / 2;
  
  //yuv数据
  //uint8_t *yuv_bytes = malloc(yuv_len);
  [self lockFramebufferForReading];
  //ARGBToNV12(self.rawBytesForImage, width * 4, yuv_bytes, width, yuv_bytes + w_x_h, width, width, height);
  //NSData *yuvData = [NSData dataWithBytesNoCopy:yuv_bytes length:yuv_len];
  NSData* rgbaData = [NSData dataWithBytes:self.rawBytesForImage length:w_x_h*4];
  [self unlockFramebufferAfterReading];
  [self.capture.delegate dataFromPostProgress:(NSData*)rgbaData frameTime:frameTime];
}
@end

@interface h264decode()
@property (nonatomic,strong) GPUImageRawDataInput* rawDataInput;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) decodeDataHandle* output;
@property (nonatomic,strong) UIView* overlayView;

@property (nonatomic,strong) UILabel* label;
@property (nonatomic,strong) UIImageView* matchlogoView;
@property (nonatomic,strong) NSDate *startTime;
@property (nonatomic,assign) int64_t lastTimestamp;
//叠加层图像
@property (nonatomic,assign) BOOL overlayImageChanged;
@property (nonatomic,strong) UIImage* overlayImage;
@end

@implementation h264decode
{
  int width;   //只有后处理有用
  int height;  //只有后处理有用
  BOOL havePostProcess; //是否使用GPUImage进行后期处理
  uint8_t* _sps;
  NSInteger _spsSize;
  uint8_t* _pps;
  NSInteger _ppsSize;
  VTDecompressionSessionRef _decoderSession;
  CMVideoFormatDescriptionRef _decoderFormatDescription;
  dispatch_queue_t _decodeQueue;
  UIView* playbackView;
  AAPLEAGLLayer* _glLayer;
  uint32_t decodePixelFormat;
  GPUImageAlphaBlendFilter* blendFilter;
  GPUImageUIElement *uielement;
  GPUImageBrightnessFilter *BrightnessFilter;
  //初始化都为false，第一次收到sps和pps后，都设置为true，然后初始化编码器，编码器初始化完毕后，马上都置为false，如果收到新的sps pps 后，则使用新的sps pps 重启解码器
  BOOL isReceiveSPS;
  BOOL isReceivePPS;
}

-(id)initWithView:(UIView*)view
{
  self = [super init];
  if(self){
    isReceiveSPS = false;
    isReceivePPS = false;
    _sps = NULL;
    _spsSize = 0;
    _pps = NULL;
    _ppsSize = 0;
    havePostProcess = false;
    decodePixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    _decodeQueue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
    if(view){
      playbackView = view;
      //CGFloat screen_width = CGRectGetWidth([UIScreen mainScreen].bounds);
      //_glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, screen_width, 200)];
      _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, playbackView.frame.size.width, playbackView.frame.size.height)];
      [playbackView.layer addSublayer:_glLayer];
    }
  }
  return self;
}

-(id)initWithView:(UIView*)view previewWidth:(int)previewWidth previewHeight:(int)previewHeight
{
  self = [super init];
  if(self){
    isReceiveSPS = false;
    isReceivePPS = false;
    _sps = NULL;
    _spsSize = 0;
    _pps = NULL;
    _ppsSize = 0;
    havePostProcess = false;
    decodePixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    _decodeQueue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
    if(view){
      playbackView = view;
      _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, previewWidth, previewHeight)];
      [playbackView.layer addSublayer:_glLayer];
    }
  }
  return self;
}

-(id)initWithGPUImageView:(UIView*)preview
{
  self = [super init];
  if(self){
    isReceiveSPS = false;
    isReceivePPS = false;
    _sps = NULL;
    _spsSize = 0;
    _pps = NULL;
    _ppsSize = 0;
    width = 1280;
    height = 720;
    havePostProcess = true;
    decodePixelFormat = kCVPixelFormatType_32BGRA;
    _decodeQueue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
    playbackView = preview;
    self.overlayImageChanged = true;
    [self initGPUImage];
  }
  return self;
}

-(void)dealloc
{
  free(_sps);
  _sps = NULL;
  free(_pps);
  _pps = NULL;
  _spsSize = _ppsSize = 0;
  [self stopH264Decoder];
}

-(void)setPreview:(UIView*)view
{
  playbackView = view;
  if(_glLayer){
    [_glLayer removeFromSuperlayer];
  }
  _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, playbackView.frame.size.width, playbackView.frame.size.height)];
  [playbackView.layer addSublayer:_glLayer];
}

-(void)showPlaybackBeginImage
{
  UIGraphicsBeginImageContext(CGSizeMake(width, height));
  CGContextRef context = UIGraphicsGetCurrentContext();
  UIImage* logo = [UIImage imageNamed:@"matchlogo.jpg"];
  [logo drawInRect:CGRectMake(0, 0, 1280, 720)];
  UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.overlayImage = newimg;
  self.overlayImageChanged = true;
  for(UIView *view in [self.overlayView subviews])
  {
    [view removeFromSuperview];
  }
  UIImageView* imageView = [[UIImageView alloc] initWithImage:self.overlayImage];
  [self.overlayView addSubview:imageView];
}

-(void)createMainOverlayImage
{
  UIGraphicsBeginImageContext(CGSizeMake(width, height));
  CGContextRef context = UIGraphicsGetCurrentContext();
  //绘制logo
  UIImage *video_logo = [UIImage imageNamed:@"video_logo.png"];
  CGRect rect = CGRectMake(1000, 62, video_logo.size.width, video_logo.size.height);
  [video_logo drawInRect:rect];
  //绘制计分牌
  UIImage* video_data = [UIImage imageNamed:@"video_data.png"];
  rect = CGRectMake(820, 567, video_data.size.width, video_data.size.height);
  [video_data drawInRect:rect];
  //绘制队伍名称
  NSString *teamname1 = @"骑士队";
  NSString *teamname2 = @"勇士队";
  NSMutableDictionary *teamnameattrs = [NSMutableDictionary dictionary];
  teamnameattrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
  teamnameattrs[NSFontAttributeName] = [UIFont systemFontOfSize:20];
  NSMutableParagraphStyle * teamnameparagraphStyle = [[NSMutableParagraphStyle alloc] init];
  teamnameparagraphStyle.alignment = NSTextAlignmentCenter;
  teamnameattrs[NSParagraphStyleAttributeName] = teamnameparagraphStyle;
  [teamname1 drawInRect:CGRectMake(870, 572, 92, 26) withAttributes:teamnameattrs];
  [teamname2 drawInRect:CGRectMake(1018, 572, 92, 26) withAttributes:teamnameattrs];
  //绘制比分
  NSString* team1point = [[NSString alloc] initWithFormat:@"%d",0];
  NSString* team2point = [[NSString alloc] initWithFormat:@"%d",0];
  NSMutableDictionary *pointattrs = [NSMutableDictionary dictionary];
  pointattrs[NSForegroundColorAttributeName] = [UIColor blackColor];
  NSMutableParagraphStyle * pointparagraphStyle = [[NSMutableParagraphStyle alloc] init];
  pointparagraphStyle.alignment = NSTextAlignmentCenter;
  pointattrs[NSParagraphStyleAttributeName] = pointparagraphStyle;
  pointattrs[NSFontAttributeName] = [UIFont systemFontOfSize:25];
  pointattrs[NSVerticalGlyphFormAttributeName] = 0; //水平居中
  [team1point drawInRect:CGRectMake(962, 568, 56, 26) withAttributes:pointattrs];
  [team2point drawInRect:CGRectMake(1110, 568, 56, 26) withAttributes:pointattrs];
  //第几节
  NSString* currentSection = [[NSString alloc] initWithFormat:@"第%d节",1];
  NSMutableDictionary *currentSectionattrs = [NSMutableDictionary dictionary];
  currentSectionattrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
  NSMutableParagraphStyle * currentSectionparagraphStyle = [[NSMutableParagraphStyle alloc] init];
  currentSectionparagraphStyle.alignment = NSTextAlignmentCenter;
  currentSectionattrs[NSParagraphStyleAttributeName] = currentSectionparagraphStyle;
  currentSectionattrs[NSFontAttributeName] = [UIFont systemFontOfSize:25];
  currentSectionattrs[NSVerticalGlyphFormAttributeName] = 0; //水平居中
  [currentSection drawInRect:CGRectMake(870, 599, 92, 26) withAttributes:currentSectionattrs];
  //倒计时
  [Quartz2DAPI drawString:context string:@"12:00" x:962 y:599 width:92 height:26 fontSize:25 color:[UIColor whiteColor]];
  //24秒
  [Quartz2DAPI drawString:context string:@"24" x:1074 y:599 width:92 height:26 fontSize:25 color:[UIColor whiteColor]];
  //暂停数
  int timeout_x = 870;
  int timeout_y = 572-10;
  for(int i=0;i<7;i++){
    [Quartz2DAPI drawRect:context color:[UIColor yellowColor] x:timeout_x+i*13 y:timeout_y width:10 height:5];
  }
  timeout_x = 1110;
  timeout_y = 572-10;
  for(int i=0;i<7;i++){
    [Quartz2DAPI drawRect:context color:[UIColor yellowColor] x:timeout_x+i*13 y:timeout_y width:10 height:5];
  }
  //BONUS
  int bonus_x = 870;
  int bonus_y = 572-10-17;
  [Quartz2DAPI drawRect:context color:[UIColor blackColor] x:bonus_x y:bonus_y width:92 height:15];
  [Quartz2DAPI drawString:context string:@"bonus" x:bonus_x y:bonus_y width:92 height:15 fontSize:14 color:[UIColor whiteColor]];
  bonus_x = 1110;
  [Quartz2DAPI drawRect:context color:[UIColor blackColor] x:bonus_x y:bonus_y width:92 height:15];
  [Quartz2DAPI drawString:context string:@"bonus" x:bonus_x y:bonus_y width:92 height:15 fontSize:14 color:[UIColor whiteColor]];
  //绘制投篮分布图
  //UIImage* shootpoints = [self drawBasketCourtWithwidth:400 height:400];
  //[shootpoints drawInRect:CGRectMake(500, 100, 400, 400)];
  UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.overlayImage = newimg;
  for(UIView *view in [self.overlayView subviews])
  {
    [view removeFromSuperview];
  }
  UIImageView* imageView = [[UIImageView alloc] initWithImage:self.overlayImage];
  [self.overlayView addSubview:imageView];
}

-(UIImage*)drawBasketCourtWithwidth:(int)width height:(int)height
{
  float PITCH_LENGTH = 28.0;
  float PITCH_WIDTH = 15.0;
  float PITCH_HALF_LENGTH = PITCH_LENGTH * 0.5;
  float PITCH_HALF_WIDTH = PITCH_WIDTH * 0.5;
  float PITCH_MARGIN = 1.0;
  float CENTER_CIRCLE_R = 1.8;
  float PAINT_ZONE_WIDTH = 4.9;
  float PAINT_ZONE_HEIGHT = 5.8;
  float RING_R = 0.45/2;
  float RING_DISTANCE = 1.575;
  float BACKBOARD_WIDTH = 1.8;
  float BACKBOARD_DISTANCE = 1.2;
  float THREE_DISTANCE = 6.75;
  float FREETHROW_R = 1.8;
  float RestrictedArea_DISTANCE = 1.25;
  float HELI_LINE_LEN = 0.375;
  BasketCourtOptions* opt = [[BasketCourtOptions alloc] init];
  UIGraphicsBeginImageContext(CGSizeMake(width, height));
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSetRGBFillColor (context, 255.0/255, 215.0/255, 0.0/255, 1);
  CGContextFillRect (context, CGRectMake (0, 0, width, height ));
  CGContextSetLineWidth(context, 1);
  CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
  //绘制篮球场
  int canvasWidth = width;
  int canvasHeight = height*2;
  [opt updateFieldSize:canvasWidth height:canvasHeight];
  float left_x = [opt screenX:-PITCH_HALF_WIDTH];
  float right_x = [opt screenX:PITCH_HALF_WIDTH];
  float top_y = [opt screenY:-PITCH_HALF_LENGTH];
  float bottom_y = [opt screenY:PITCH_HALF_LENGTH];
  //绘制边线
  //上边线
  CGContextSetLineWidth(context, 2);
  CGContextMoveToPoint(context, left_x, top_y);
  CGContextAddLineToPoint(context, right_x, top_y);
  CGContextStrokePath(context);
  
  //右边线
  CGContextSetLineWidth(context, 2);
  CGContextMoveToPoint(context, right_x, top_y);
  CGContextAddLineToPoint(context, right_x, bottom_y);
  CGContextStrokePath(context);
  
  //下边线
  CGContextSetLineWidth(context, 2);
  CGContextMoveToPoint(context, right_x, bottom_y);
  CGContextAddLineToPoint(context, left_x, bottom_y);
  CGContextStrokePath(context);
  
  //左边线
  CGContextSetLineWidth(context, 2);
  CGContextMoveToPoint(context, left_x, bottom_y);
  CGContextAddLineToPoint(context, left_x, top_y);
  CGContextStrokePath(context);
  
  //绘制中线
  int center_radius = [opt scale:CENTER_CIRCLE_R];
  int center_x = [opt centerX];
  int center_y = [opt centerY];
  [Quartz2DAPI drawLine:context left:left_x top:center_y right:right_x bottom:center_y];
  
  //绘制中圈
  CGContextSetRGBFillColor (context, 1, 1, 0, 0.5);
  CGContextAddArc(context, center_x, center_y, center_radius, 0, M_PI*2, 0);
  CGContextFillPath(context);
  
  //绘制油漆区
  float paint_left_x = [opt screenX:-PAINT_ZONE_WIDTH*0.5];
  float paint_zone_width = [opt scale:PAINT_ZONE_WIDTH];
  float paint_zone_height = [opt scale:PAINT_ZONE_HEIGHT];
  //CGContextSetRGBFillColor (context, 0, 1, 1, 1);
  CGContextSetFillColorWithColor(context, [UIColor colorWithRed:148.0/255 green:0 blue:211.0/255 alpha:1].CGColor);
  CGContextFillRect (context, CGRectMake (paint_left_x, top_y, paint_zone_width, paint_zone_height ));
  CGContextFillRect (context, CGRectMake (paint_left_x, bottom_y-paint_zone_height, paint_zone_width, paint_zone_height ));
  
  //绘制篮圈,三分线,合理冲撞区
  float ring_y = [opt screenY:-(PITCH_HALF_LENGTH-RING_DISTANCE)];
  float ring_r = [opt scale:RING_R];
  float three_r = [opt scale:THREE_DISTANCE];
  float heli_r = [opt scale:RestrictedArea_DISTANCE];
  [Quartz2DAPI drawStrokeCircle:context x:[opt centerX] y:ring_y radius:ring_r border:1];    //绘制篮圈
  [Quartz2DAPI drawHalfCircle:context x:[opt centerX] y:ring_y radius:three_r clock:0];//绘制三分线
  [Quartz2DAPI drawHalfCircle:context x:[opt centerX] y:ring_y radius:heli_r clock:0]; //绘制合理冲撞区
  float three_left_x = [opt screenX:(-THREE_DISTANCE)];
  float three_right_x = [opt screenX:(THREE_DISTANCE)];
  float three_y = [opt screenY:-(PITCH_HALF_LENGTH-RING_DISTANCE)];
  [Quartz2DAPI drawLine:context left:three_left_x top:top_y right:three_left_x bottom:three_y];
  [Quartz2DAPI drawLine:context left:three_right_x top:top_y right:three_right_x bottom:three_y];
  //绘制篮板
  float bankboard_left_x = [opt screenX:(-BACKBOARD_WIDTH*0.5)];
  float bankboard_right_x = [opt screenX:(BACKBOARD_WIDTH*0.5)];
  float bankboard_y = [opt screenY:-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [Quartz2DAPI drawLine:context left:bankboard_left_x top:bankboard_y right:bankboard_right_x bottom:bankboard_y];
  //绘制篮圈和篮板的连线
  [Quartz2DAPI drawLine:context left:[opt centerX] top:bankboard_y right:[opt centerX] bottom:ring_y-ring_r];
  
  ring_y = [opt screenY:(PITCH_HALF_LENGTH-RING_DISTANCE)];
  [Quartz2DAPI drawStrokeCircle:context x:[opt centerX] y:ring_y radius:ring_r border:1];         //绘制篮圈
  [Quartz2DAPI drawHalfCircle:context x:[opt centerX] y:ring_y radius:three_r clock:1];//绘制三分线
  [Quartz2DAPI drawHalfCircle:context x:[opt centerX] y:ring_y radius:heli_r clock:1]; //绘制合理冲撞区
  three_y = [opt screenY:(PITCH_HALF_LENGTH-RING_DISTANCE)];
  [Quartz2DAPI drawLine:context left:three_left_x top:bottom_y right:three_left_x bottom:three_y];
  [Quartz2DAPI drawLine:context left:three_right_x top:bottom_y right:three_right_x bottom:three_y];
  //绘制篮板
  bankboard_y = [opt screenY:(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [Quartz2DAPI drawLine:context left:bankboard_left_x top:bankboard_y right:bankboard_right_x bottom:bankboard_y];
  //绘制篮圈和篮板的连线
  [Quartz2DAPI drawLine:context left:[opt centerX] top:ring_y+ring_r right:[opt centerX] bottom:bankboard_y];
  
  
  //修正合理冲撞区
  float heli_left_x = [opt screenX:(-RestrictedArea_DISTANCE)];
  float heli_right_x = [opt screenX:(RestrictedArea_DISTANCE)];
  float heli_top_y = [opt screenY:-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE-HELI_LINE_LEN)];
  float heli_bottom_y = [opt screenY:-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [Quartz2DAPI drawLine:context left:heli_left_x top:heli_bottom_y right:heli_left_x bottom:heli_top_y];
  [Quartz2DAPI drawLine:context left:heli_right_x top:heli_bottom_y right:heli_right_x bottom:heli_top_y];
  heli_top_y = [opt screenY:(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE-HELI_LINE_LEN)];
  heli_bottom_y = [opt screenY:(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [Quartz2DAPI drawLine:context left:heli_left_x top:heli_bottom_y right:heli_left_x bottom:heli_top_y];
  [Quartz2DAPI drawLine:context left:heli_right_x top:heli_bottom_y right:heli_right_x bottom:heli_top_y];
  
  //绘制罚球半圆
  float freethrow_x = [opt centerX];
  float freethrow_r = [opt scale:(FREETHROW_R)];
  float freethrow_y = [opt screenY:-(PITCH_HALF_LENGTH-PAINT_ZONE_HEIGHT)];
  [Quartz2DAPI drawHalfCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:0];
  [Quartz2DAPI drawHalfDashCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:1];
  freethrow_y = [opt screenY:(PITCH_HALF_LENGTH-PAINT_ZONE_HEIGHT)];
  [Quartz2DAPI drawHalfCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:1];
  [Quartz2DAPI drawHalfDashCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:0];
  
  UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newimg;
}

-(void)initGPUImage
{
  self.rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:nil size:CGSizeMake(0, 0)];
  self.filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, 128*3, 72*3)];
  [playbackView addSubview:self.filterView];
  //[self setGPUImageViewRect];
  self.output = [[decodeDataHandle alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:YES capture:self];
  
  // 水印
  self.startTime = [NSDate date];
  self.lastTimestamp = -1;
  
  self.overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
  self.overlayView.backgroundColor = [UIColor clearColor];
  /*self.label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 440, 200)];
  self.label.text = @"我是水印";
  self.label.font = [UIFont systemFontOfSize:50];
  self.label.textColor = [UIColor blueColor];
  self.label.backgroundColor = [UIColor clearColor];
  UIImage *video_logo = [UIImage imageNamed:@"video_logo.png"];
  UIImageView *logo_imageView = [[UIImageView alloc] initWithImage:video_logo];
  CGRect logo_frame = logo_imageView.frame;
  logo_frame.origin = CGPointMake(1000, 62);
  logo_imageView.frame = logo_frame;
  [self.overlayView addSubview:logo_imageView];
  [self.overlayView addSubview:self.label];
  
  UIImage* video_data = [UIImage imageNamed:@"video_data.png"];
  UIImageView* data_imageView = [[UIImageView alloc] initWithImage:video_data];
  CGRect data_frame = data_imageView.frame;
  data_frame.origin = CGPointMake(820, 567);
  data_imageView.frame = data_frame;
  [self.overlayView addSubview:data_imageView];
  
  UILabel* team1name = [[UILabel alloc] initWithFrame:CGRectMake(870, 567, 148, 26)];
  team1name.text = @"骑士队";
  team1name.font = [UIFont systemFontOfSize:25];
  team1name.textColor = [UIColor whiteColor];
  team1name.backgroundColor = [UIColor clearColor];
  [self.overlayView addSubview:team1name];
  UIImage* matchlogo = [UIImage imageNamed:@"lanuch.png"];
  self.matchlogoView = [[UIImageView alloc] initWithImage:matchlogo];
  self.matchlogoView.frame = CGRectMake(480, 100, 400, 400);*/
  [self createMainOverlayImage];
  
  uielement = [[GPUImageUIElement alloc] initWithView:self.overlayView];
  blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
  blendFilter.mix = 1.0f;
  BrightnessFilter = [[GPUImageBrightnessFilter alloc] init];
  BrightnessFilter.brightness = 0;
  
  //设置滤镜链
  [self.rawDataInput addTarget:BrightnessFilter];
  [BrightnessFilter addTarget:blendFilter];
  [uielement addTarget:blendFilter];
  [blendFilter addTarget:self.filterView];
  [blendFilter addTarget:self.output];
  
  __unsafe_unretained GPUImageUIElement *weakUIElementInput = uielement;
  __weak typeof(self) ws = self;
  [BrightnessFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
    if(ws.overlayImageChanged){
      [weakUIElementInput update];
      ws.overlayImageChanged = false;
    }
    /*if(ws.lastTimestamp == -1){
      ws.lastTimestamp = [[NSDate date] timeIntervalSince1970]*1000;
      [weakUIElementInput update];
    }else{
      int64_t now = [[NSDate date] timeIntervalSince1970]*1000;
      int64_t interval = now - ws.lastTimestamp;
      if(interval >= 100){
        ws.label.text = [NSString stringWithFormat:@"Time: %f s", -[ws.startTime timeIntervalSinceNow]];
        [weakUIElementInput update];
        ws.lastTimestamp = now;
      }
    }*/
  }];
}

-(void)setGPUImageViewRect
{
  self.filterView.translatesAutoresizingMaskIntoConstraints = NO;
  NSLayoutConstraint* contraint_width = [NSLayoutConstraint constraintWithItem:self.filterView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:playbackView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
  [playbackView addConstraint:contraint_width];
  
  NSLayoutConstraint* contraint_height = [NSLayoutConstraint constraintWithItem:self.filterView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:playbackView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
  [playbackView addConstraint:contraint_height];
}

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
  
  CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
  *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(void)postProcess:(NSData*)brgaBuffer width:(int)width height:(int)height
{
  [self.rawDataInput updateDataFromBytes:(void*)brgaBuffer.bytes size:CGSizeMake(width, height)];
  [self.rawDataInput processData];
  
  [uielement update];
}

-(bool)startH264Decoder{
  if(!isReceiveSPS || !isReceivePPS){
    return FALSE;
  }
  if(_decoderSession){
    return FALSE;
  }
  const uint8_t* const parameterSetPointers[2] = {_sps,_pps};
  const size_t parameterSetSizes[2] = {_spsSize,_ppsSize};
  OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_decoderFormatDescription);
  if(status == noErr){
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    //uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &decodePixelFormat) };
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

-(void)stopH264Decoder{
  if(_decoderSession){
    VTDecompressionSessionInvalidate(_decoderSession);
    CFRelease(_decoderSession);
    _decoderSession = NULL;
  }
  if(_decoderFormatDescription){
    CFRelease(_decoderFormatDescription);
    _decoderFormatDescription = NULL;
  }
}

-(CVPixelBufferRef)decodeframe:(Byte*)buffer size:(size_t)size{
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

-(void)decodeH264WithoutHeader:(NSData*)nalu
{
  size_t size = nalu.length+4;
  Byte* buffer = malloc(size);
  [nalu getBytes:buffer+4 length:nalu.length];
  dispatch_sync(_decodeQueue,^{
    uint32_t nalSize = (uint32_t)(nalu.length);
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
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
      case 0x07:
        NSLog(@"Nal type is SPS");
        if(_sps != NULL){
          free(_sps);
        }
        _spsSize = size - 4;
        _sps = malloc(_spsSize);
        memcpy(_sps, buffer + 4, _spsSize);
        isReceiveSPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
          //重置元数据标记
          isReceivePPS = false;
          isReceiveSPS = false;
        }
        break;
      case 0x08:
        NSLog(@"Nal type is PPS");
        if(_pps != NULL){
          free(_pps);
        }
        _ppsSize = size - 4;
        _pps = malloc(_ppsSize);
        memcpy(_pps, buffer + 4, _ppsSize);
        isReceivePPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
          //重置元数据标记
          isReceivePPS = false;
          isReceiveSPS = false;
        }
        break;
        
      default:
        NSLog(@"Nal type is B/P frame");
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
    }
    
    if(pixelBuffer) {
      if(havePostProcess){
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        Byte* pixel = CVPixelBufferGetBaseAddress(pixelBuffer);
        int length = bufferWidth*bufferHeight*4;
        NSData* BRGABuffer = [[NSData alloc] initWithBytes:pixel length:length];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        dispatch_sync(dispatch_get_main_queue(), ^{
          [self postProcess:BRGABuffer width:bufferWidth height:bufferHeight];
        });
      }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
          _glLayer.pixelBuffer = pixelBuffer;
        });
      }
      CVPixelBufferRelease(pixelBuffer);
    }
    
    free(buffer);
  });
  
}

-(void)decodeH264:(NSData*)nalu
{
  size_t size = [nalu length];
  Byte* buffer = malloc(size);
  [nalu getBytes:buffer length:size];
  dispatch_sync(_decodeQueue,^{
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
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
      case 0x07:
        NSLog(@"Nal type is SPS");
        if(_sps != NULL){
          free(_sps);
        }
        _spsSize = size - 4;
        _sps = malloc(_spsSize);
        memcpy(_sps, buffer + 4, _spsSize);
        isReceiveSPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
        }
        break;
      case 0x08:
        NSLog(@"Nal type is PPS");
        if(_pps != NULL){
          free(_pps);
        }
        _ppsSize = size - 4;
        _pps = malloc(_ppsSize);
        memcpy(_pps, buffer + 4, _ppsSize);
        isReceivePPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
        }
        break;
        
      default:
        NSLog(@"Nal type is B/P frame");
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
    }
    
    if(pixelBuffer) {
      if(havePostProcess){
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        Byte* pixel = CVPixelBufferGetBaseAddress(pixelBuffer);
        int length = bufferWidth*bufferHeight*4;
        NSData* BRGABuffer = [[NSData alloc] initWithBytesNoCopy:pixel length:length];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        dispatch_sync(dispatch_get_main_queue(), ^{
          [self postProcess:BRGABuffer width:bufferWidth height:bufferHeight];
        });
      }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
          _glLayer.pixelBuffer = pixelBuffer;
        });
      }
      CVPixelBufferRelease(pixelBuffer);
    }
    
    free(buffer);
  });
}

@end
