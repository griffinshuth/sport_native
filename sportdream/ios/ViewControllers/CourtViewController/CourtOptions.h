//
//  CourtOptions.h
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CourtOptions : NSObject
{
  int M_canvas_width;
  int M_canvas_height;
  bool M_zoomed;
  double M_field_scale;
  int M_field_center_x;
  int M_field_center_y;
}
- (void) updateFieldSize:(int) canvas_width height:(int) canvas_height;
- (int) scale:(double)len;
- (int) screenX:(double)x;
- (int) screenY:(double)y;
- (double) fieldX:(int)x;
- (double) fieldY:(int)y;
- (int) centerX;
- (int) centerY;
@end
