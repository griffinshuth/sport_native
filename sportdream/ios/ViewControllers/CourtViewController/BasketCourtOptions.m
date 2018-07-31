//
//  BasketCourtOptions.m
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "BasketCourtOptions.h"

@implementation BasketCourtOptions
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
    
    M_canvas_width = -1;
    M_canvas_height = -1;
    M_zoomed = false;
    M_field_scale = 1.0;
    M_field_center_x = 0;
    M_field_center_y = 0;
  }
  return self;
}

- (void) updateFieldSize:(int) canvas_width height:(int) canvas_height
{
  M_canvas_width = canvas_width;
  M_canvas_height = canvas_height;
  float total_pitch_l = PITCH_LENGTH+PITCH_MARGIN*2+1;
  float total_pitch_w = PITCH_WIDTH+PITCH_MARGIN*2;
  M_field_scale = canvas_height/total_pitch_l;
  float field_width = canvas_width;
  if(total_pitch_w*M_field_scale > field_width){
    M_field_scale = field_width/total_pitch_w;
  }
  if(M_field_scale < MIN_FIELD_SCALE){
    M_field_scale = MIN_FIELD_SCALE;
  }
  M_field_center_x = field_width/2;
  M_field_center_y = canvas_height/2;
}
- (int) scale:(double)len
{
  return len*M_field_scale;
}
- (int) screenX:(double)x
{
  return M_field_center_x + [self scale:x];
}
- (int) screenY:(double)y
{
  return M_field_center_y + [self scale:y];
}
- (double) fieldX:(int)x
{
  return (x-M_field_center_x)/M_field_scale;
}
- (double) fieldY:(int)y
{
  return (y - M_field_center_y)/M_field_scale;
}
- (int) centerX
{
  return M_field_center_x;
}
- (int) centerY
{
  return M_field_center_y;
}

@end
