//
//  BasketStadium.m
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "BasketStadium.h"
#import "BasketCourtOptions.h"
#import "MatchDataUI.h"

@implementation BasketStadium
{
  float PITCH_LENGTH;
  float PITCH_WIDTH;
  float PITCH_HALF_LENGTH;
  float PITCH_HALF_WIDTH;
  float PITCH_MARGIN;
  float CENTER_CIRCLE_R;
  float PAINT_ZONE_WIDTH;
  float PAINT_ZONE_HEIGHT;
  float RING_R;
  float RING_DISTANCE;
  float BACKBOARD_WIDTH;
  float BACKBOARD_DISTANCE;
  float THREE_DISTANCE;
  float FREETHROW_R;
  float RestrictedArea_DISTANCE;
  float HELI_LINE_LEN;
  float MIN_FIELD_SCALE;
  
  BasketCourtOptions* opt;
  Boolean isTimeStart;
  BOOL isneedrender;
  //队员头像
  UIImage* currentImage;
  float current_x;
  float current_y;
  NSMutableArray* team1Images;
  NSMutableArray* team2Images;
  //篮球和号码图像
  UIImage* basketballImage;
  NSMutableArray* redNumbersImages;
  NSMutableArray* blackNumbersImages;
  //投篮点分布信息
  NSArray* shootpoints;
  //当前路径
  NSMutableArray* tempPath;
  BOOL preview;
  
  //定时器
  NSTimer* timer;
}

-(id)init
{
  self = [super init];
  if(self){
    PITCH_LENGTH = 28.0;
    PITCH_WIDTH = 15.0;
    PITCH_HALF_LENGTH = PITCH_LENGTH * 0.5;
    PITCH_HALF_WIDTH = PITCH_WIDTH * 0.5;
    PITCH_MARGIN = 1.0;
    CENTER_CIRCLE_R = 1.8;
    PAINT_ZONE_WIDTH = 4.9;
    PAINT_ZONE_HEIGHT = 5.8;
    RING_R = 0.45/2;
    RING_DISTANCE = 1.575;
    BACKBOARD_WIDTH = 1.8;
    BACKBOARD_DISTANCE = 1.2;
    THREE_DISTANCE = 6.75;
    FREETHROW_R = 1.8;
    RestrictedArea_DISTANCE = 1.25;
    HELI_LINE_LEN = 0.375;
    
    opt = [[BasketCourtOptions alloc] init];
    
    isTimeStart = false;
    isneedrender = false;
    current_x = -10000;
    current_y = -10000;
    team1Images = [[NSMutableArray alloc] init];
    team2Images = [[NSMutableArray alloc] init];
    redNumbersImages = [[NSMutableArray alloc] init];
    basketballImage = [UIImage imageNamed:@"basketball.png"];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred0.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred1.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred2.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred3.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred4.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred5.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred6.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred7.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred8.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred9.png"]];
    [redNumbersImages addObject:[UIImage imageNamed:@"numberred10.png"]];
    blackNumbersImages = [[NSMutableArray alloc] init];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack0.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack1.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack2.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack3.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack4.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack5.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack6.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack7.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack8.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack9.png"]];
    [blackNumbersImages addObject:[UIImage imageNamed:@"numberblack10.png"]];
    
    preview = false;
    tempPath = [[NSMutableArray alloc] init];
    
  }
  return self;
}

-(void)dealloc
{
  [timer invalidate];
}

-(void)runloop
{
  if(!preview){
    if(isneedrender){
      [self setNeedsDisplay];
      isneedrender = false;
    }
  }else{
    CGPoint point=CGPointFromString([tempPath objectAtIndex:0]);
    current_x = [opt screenX:point.x];
    current_y = [opt screenY:point.y];
    [tempPath removeObjectAtIndex:0];
    if([tempPath count] == 0){
      preview = false;
    }
    [self setNeedsDisplay];
  }
}

//触摸事件
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;{
  UITouch *touch = [touches anyObject];
  CGPoint currentLocation = [touch locationInView:self];
  float x = currentLocation.x;
  float y = currentLocation.y;
  current_x = x;
  current_y = y;
  isneedrender = true;
  CGPoint point;
  point.x = [opt fieldX:x];
  point.y = [opt fieldY:y];
  [tempPath addObject:NSStringFromCGPoint(point)];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint currentLocation = [touch locationInView:self];
  float x = currentLocation.x;
  float y = currentLocation.y;
  current_x = x;
  current_y = y;
  isneedrender = true;
  CGPoint point;
  point.x = [opt fieldX:x];
  point.y = [opt fieldY:y];
  [tempPath addObject:NSStringFromCGPoint(point)];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  preview = true;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  
}

-(void)initImage
{
  UIImageView* imageView = [MatchDataUI createImageOfUrl:self.currentMember[@"image"] width:32 height:32];
  currentImage = [BasketStadium createCircleImage:imageView.image];
  NSArray* team1Members = self.gameData[@"team1Members"];
  for(int i=0;i<[team1Members count];i++){
    NSDictionary* member = [team1Members objectAtIndex:i];
    UIImageView* imageView = [MatchDataUI createImageOfUrl:member[@"image"] width:32 height:32];
    [team1Images addObject:[BasketStadium createCircleImage:imageView.image]];
  }
  
  NSArray* team2Members = self.gameData[@"team2Members"];
  for(int i=0;i<[team2Members count];i++){
    NSDictionary* member = [team2Members objectAtIndex:i];
    UIImageView* imageView = [MatchDataUI createImageOfUrl:member[@"image"] width:32 height:32];
    [team2Images addObject:[BasketStadium createCircleImage:imageView.image]];
  }
  
  NSDictionary* teamdataStatistics;
  if(self.teamindex == 0){
    teamdataStatistics = self.gameData[@"team1dataStatistics"];
  }else{
    teamdataStatistics = self.gameData[@"team2dataStatistics"];
  }
  NSString* uid = nil;
  if([self.currentMember[@"id"] isKindOfClass:[NSString class]]){
    uid = self.currentMember[@"id"];
  }else{
    uid = [[NSString alloc] initWithFormat:@"%d",[self.currentMember[@"id"] intValue]];
  }
  if(teamdataStatistics[uid]){
    if(teamdataStatistics[uid][@"shoot"]){
      shootpoints = teamdataStatistics[uid][@"shoot"];
    }
  }
}

+(UIImage*)createCircleImage:(UIImage*)image
{
  UIGraphicsBeginImageContext(CGSizeMake(image.size.width, image.size.height));
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
  CGContextAddEllipseInRect(context, rect);
  CGContextClip(context);
  [image drawInRect:rect];
  UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newimg;
}

-(void)drawLine:(CGContextRef)context left:(float)left top:(float)top right:(float)right bottom:(float)bottom
{
  CGContextSetLineWidth(context, 2);
  CGContextMoveToPoint(context, left, top);
  CGContextAddLineToPoint(context, right, bottom);
  CGContextStrokePath(context);
}

-(void)drawCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius
{
  CGContextSetRGBFillColor (context, 1, 0.5, 0.5, 1);
  CGContextAddArc(context, x, y, radius, 0, M_PI*2, 0);
  CGContextFillPath(context);
}

-(void)drawStrokeCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius border:(int)border
{
  CGContextSetLineWidth(context, border);
  CGContextSetRGBFillColor (context, 1, 0.5, 0.5, 1);
  CGContextAddArc(context, x, y, radius, 0, M_PI*2, 0);
  CGContextStrokePath(context);
}

-(void)drawColorCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius color:(UIColor*)color
{
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextAddArc(context, x, y, radius, 0, M_PI*2, 0);
  CGContextFillPath(context);
}

-(void)drawHalfCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius clock:(int)clock
{

  CGContextSetLineWidth(context, 2);
  CGContextSetRGBFillColor (context, 1, 0.5, 0.5, 1);
  CGContextAddArc(context, x, y, radius, 0, M_PI, clock);
  CGContextStrokePath(context);
}

-(void)drawHalfDashCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius clock:(int)clock
{
  CGContextSaveGState(context);
  CGContextRef temp = UIGraphicsGetCurrentContext();
  CGContextSetLineWidth(temp, 2);
  double lengths[] = {5,5};
  CGContextSetLineDash(temp, 0, lengths,2);
  CGContextSetRGBFillColor (temp, 1, 0.5, 0.5, 1);
  CGContextAddArc(temp, x, y, radius, 0, M_PI, clock);
  CGContextStrokePath(temp);
  CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect {
  CGRect rx = rect;
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetRGBFillColor (context, 255.0/255, 215.0/255, 0.0/255, 1);
  CGContextFillRect (context, CGRectMake (0, 0, rx.size.width, rx.size.height ));
  CGContextSetLineWidth(context, 1);
  CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
  
  //绘制篮球场
  int canvasWidth = rx.size.width;
  int canvasHeight = rx.size.height*2;
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
  [self drawLine:context left:left_x top:center_y right:right_x bottom:center_y];
  
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
  [self drawStrokeCircle:context x:[opt centerX] y:ring_y radius:ring_r border:1];    //绘制篮圈
  [self drawHalfCircle:context x:[opt centerX] y:ring_y radius:three_r clock:0];//绘制三分线
  [self drawHalfCircle:context x:[opt centerX] y:ring_y radius:heli_r clock:0]; //绘制合理冲撞区
  float three_left_x = [opt screenX:(-THREE_DISTANCE)];
  float three_right_x = [opt screenX:(THREE_DISTANCE)];
  float three_y = [opt screenY:-(PITCH_HALF_LENGTH-RING_DISTANCE)];
  [self drawLine:context left:three_left_x top:top_y right:three_left_x bottom:three_y];
  [self drawLine:context left:three_right_x top:top_y right:three_right_x bottom:three_y];
  //绘制篮板
  float bankboard_left_x = [opt screenX:(-BACKBOARD_WIDTH*0.5)];
  float bankboard_right_x = [opt screenX:(BACKBOARD_WIDTH*0.5)];
  float bankboard_y = [opt screenY:-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [self drawLine:context left:bankboard_left_x top:bankboard_y right:bankboard_right_x bottom:bankboard_y];
  //绘制篮圈和篮板的连线
  [self drawLine:context left:[opt centerX] top:bankboard_y right:[opt centerX] bottom:ring_y-ring_r];
  
  ring_y = [opt screenY:(PITCH_HALF_LENGTH-RING_DISTANCE)];
  [self drawStrokeCircle:context x:[opt centerX] y:ring_y radius:ring_r border:1];         //绘制篮圈
  [self drawHalfCircle:context x:[opt centerX] y:ring_y radius:three_r clock:1];//绘制三分线
  [self drawHalfCircle:context x:[opt centerX] y:ring_y radius:heli_r clock:1]; //绘制合理冲撞区
  three_y = [opt screenY:(PITCH_HALF_LENGTH-RING_DISTANCE)];
  [self drawLine:context left:three_left_x top:bottom_y right:three_left_x bottom:three_y];
  [self drawLine:context left:three_right_x top:bottom_y right:three_right_x bottom:three_y];
  //绘制篮板
  bankboard_y = [opt screenY:(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [self drawLine:context left:bankboard_left_x top:bankboard_y right:bankboard_right_x bottom:bankboard_y];
  //绘制篮圈和篮板的连线
  [self drawLine:context left:[opt centerX] top:ring_y+ring_r right:[opt centerX] bottom:bankboard_y];
  
  
  //修正合理冲撞区
  float heli_left_x = [opt screenX:(-RestrictedArea_DISTANCE)];
  float heli_right_x = [opt screenX:(RestrictedArea_DISTANCE)];
  float heli_top_y = [opt screenY:-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE-HELI_LINE_LEN)];
  float heli_bottom_y = [opt screenY:-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [self drawLine:context left:heli_left_x top:heli_bottom_y right:heli_left_x bottom:heli_top_y];
  [self drawLine:context left:heli_right_x top:heli_bottom_y right:heli_right_x bottom:heli_top_y];
  heli_top_y = [opt screenY:(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE-HELI_LINE_LEN)];
  heli_bottom_y = [opt screenY:(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE)];
  [self drawLine:context left:heli_left_x top:heli_bottom_y right:heli_left_x bottom:heli_top_y];
  [self drawLine:context left:heli_right_x top:heli_bottom_y right:heli_right_x bottom:heli_top_y];
  
  //绘制罚球半圆
  float freethrow_x = [opt centerX];
  float freethrow_r = [opt scale:(FREETHROW_R)];
  float freethrow_y = [opt screenY:-(PITCH_HALF_LENGTH-PAINT_ZONE_HEIGHT)];
  [self drawHalfCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:0];
  [self drawHalfDashCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:1];
  freethrow_y = [opt screenY:(PITCH_HALF_LENGTH-PAINT_ZONE_HEIGHT)];
  [self drawHalfCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:1];
  [self drawHalfDashCircle:context x:freethrow_x y:freethrow_y radius:freethrow_r clock:0];
  
  //绘制当前球员头像
  if(current_x == -10000){
    current_x = [opt centerX]-16;
  }
  if(current_y == -10000){
    current_y = [opt centerY]-16;
  }
  [currentImage drawInRect:CGRectMake(current_x-12, current_y-12, 24, 24)];
  [basketballImage drawInRect:CGRectMake(current_x-6, current_y-6, 12, 12)];
  //绘制队伍1队员头像
  float team1imageX = [opt centerX] - 100;
  float team1imageY = [opt centerY] - 60;
  for(int i=0;i<[team1Images count];i++){
    [team1Images[i] drawInRect:CGRectMake(team1imageX+i*40, team1imageY, 24, 24)];
    float number_x = team1imageX+i*40-8;
    float number_y = team1imageY-8;
    [self drawColorCircle:context x:number_x+8 y:number_y+8 radius:8 color:[UIColor blackColor]];
    [redNumbersImages[i+1] drawInRect:CGRectMake(number_x, number_y, 16, 16)];
  }
  //绘制队伍2队员头像
  float team2imageX = [opt centerX] - 100;
  float team2imageY = [opt centerY] + 18;
  for(int i=0;i<[team2Images count];i++){
    [team2Images[i] drawInRect:CGRectMake(team2imageX+i*40, team2imageY, 24, 24)];
    float number_x = team2imageX+i*40-8;
    float number_y = team2imageY-8;
    [self drawColorCircle:context x:number_x+8 y:number_y+8 radius:8 color:[UIColor whiteColor]];
    [blackNumbersImages[i+1] drawInRect:CGRectMake(number_x, number_y, 16, 16)];
  }
  //绘制投篮点
  if(shootpoints){
    for(int i=0;i<[shootpoints count];i++){
      float paintedX = [opt screenX:[shootpoints[i][@"x"] floatValue]];
      float paintedY = [opt screenY:[shootpoints[i][@"y"] floatValue]];
      BOOL isScore = [shootpoints[i][@"score"] boolValue];
      if(isScore){
        [self drawColorCircle:context x:paintedX y:paintedY radius:4 color:[UIColor blackColor]];
      }else{
        [self drawColorCircle:context x:paintedX y:paintedY radius:4 color:[UIColor redColor]];
      }
    }
  }
  
  //绘制临时直线
  if([tempPath count] >1){
    CGPoint originPoint = CGPointFromString([tempPath objectAtIndex:0]);
    CGContextSetLineWidth(context, 2);
    CGContextMoveToPoint(context, [opt screenX:originPoint.x], [opt screenY:originPoint.y]);
    for(int i=1;i<[tempPath count];i++){
      CGPoint point = CGPointFromString([tempPath objectAtIndex:i]);
      CGContextAddLineToPoint(context, [opt screenX:point.x], [opt screenY:point.y]);
    }
    CGContextStrokePath(context);
  }
  
  
  if(!isTimeStart){
    timer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(runloop) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    isTimeStart = true;
  }
}

@end
