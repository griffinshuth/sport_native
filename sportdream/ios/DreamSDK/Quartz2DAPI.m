//
//  Quartz2DAPI.m
//  sportdream
//
//  Created by lili on 2018/6/7.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "Quartz2DAPI.h"

@implementation Quartz2DAPI
+(void)drawLine:(CGContextRef)context left:(float)left top:(float)top right:(float)right bottom:(float)bottom
{
  CGContextSetLineWidth(context, 2);
  CGContextMoveToPoint(context, left, top);
  CGContextAddLineToPoint(context, right, bottom);
  CGContextStrokePath(context);
}

+(void)drawCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius
{
  CGContextSetRGBFillColor (context, 1, 0.5, 0.5, 1);
  CGContextAddArc(context, x, y, radius, 0, M_PI*2, 0);
  CGContextFillPath(context);
}

+(void)drawStrokeCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius border:(int)border
{
  CGContextSetLineWidth(context, border);
  CGContextSetRGBFillColor (context, 1, 0.5, 0.5, 1);
  CGContextAddArc(context, x, y, radius, 0, M_PI*2, 0);
  CGContextStrokePath(context);
}

+(void)drawColorCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius color:(UIColor*)color
{
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextAddArc(context, x, y, radius, 0, M_PI*2, 0);
  CGContextFillPath(context);
}

+(void)drawHalfCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius clock:(int)clock
{
  
  CGContextSetLineWidth(context, 2);
  CGContextSetRGBFillColor (context, 1, 0.5, 0.5, 1);
  CGContextAddArc(context, x, y, radius, 0, M_PI, clock);
  CGContextStrokePath(context);
}

+(void)drawHalfDashCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius clock:(int)clock
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

+(void)drawString:(CGContextRef)context string:(NSString*)string x:(float)x y:(float)y width:(float)width height:(float)height fontSize:(int)fontSize color:(UIColor*)color
{
  NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
  attrs[NSForegroundColorAttributeName] = color;
  NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.alignment = NSTextAlignmentCenter;
  attrs[NSParagraphStyleAttributeName] = paragraphStyle;
  attrs[NSFontAttributeName] = [UIFont systemFontOfSize:fontSize];
  attrs[NSVerticalGlyphFormAttributeName] = 0; //水平居中
  [string drawInRect:CGRectMake(x, y, width, height) withAttributes:attrs];
}
+(void)drawRect:(CGContextRef)context color:(UIColor*)color x:(float)x y:(float)y width:(float)width height:(float)height
{
  CGContextSetFillColorWithColor(context,color.CGColor);
  CGContextFillRect (context, CGRectMake (x, y, width, height ));
}
@end
