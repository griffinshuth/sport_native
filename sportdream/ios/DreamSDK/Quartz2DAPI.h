//
//  Quartz2DAPI.h
//  sportdream
//
//  Created by lili on 2018/6/7.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Quartz2DAPI : NSObject
+(void)drawLine:(CGContextRef)context left:(float)left top:(float)top right:(float)right bottom:(float)bottom;
+(void)drawCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius;
+(void)drawStrokeCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius border:(int)border;
+(void)drawColorCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius color:(UIColor*)color;
+(void)drawHalfCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius clock:(int)clock;
+(void)drawHalfDashCircle:(CGContextRef)context x:(float)x y:(float)y radius:(float)radius clock:(int)clock;
+(void)drawString:(CGContextRef)context string:(NSString*)string x:(float)x y:(float)y width:(float)width height:(float)height fontSize:(int)fontSize color:(UIColor*)color;
+(void)drawRect:(CGContextRef)context color:(UIColor*)color x:(float)x y:(float)y width:(float)width height:(float)height;
@end
