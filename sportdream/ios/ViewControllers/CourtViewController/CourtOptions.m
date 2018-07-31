//
//  CourtOptions.m
//  sportdream
//
//  Created by lili on 2018/6/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CourtOptions.h"

@implementation CourtOptions
{
  float PITCH_LENGTH;
  float PITCH_WIDTH;
  float PITCH_HALF_LENGTH;
  float PITCH_HALF_WIDTH;
  float PITCH_MARGIN;
  float CENTER_CIRCLE_R;
  float PENALTY_AREA_LENGTH;
  float PENALTY_AREA_WIDTH;
  float PENALTY_CIRCLE_R;
  float PENALTY_SPOT_DIST;
  float GOAL_WIDTH;
  float GOAL_HALF_WIDTH;
  float GOAL_AREA_LENGTH;
  float GOAL_AREA_WIDTH;
  float GOAL_DEPTH;
  float CORNER_ARC_R;
  float GOAL_POST_RADIUS;
  
  float MIN_FIELD_SCALE;
  float MAX_FIELD_SCALE;
}
- (id) init{
  self = [super init];
  PITCH_LENGTH = 105.0;
  PITCH_WIDTH = 68.0;
  PITCH_HALF_LENGTH = PITCH_LENGTH * 0.5;
  PITCH_HALF_WIDTH = PITCH_WIDTH * 0.5;
  PITCH_MARGIN = 5.0;
  CENTER_CIRCLE_R = 9.15;
  PENALTY_AREA_LENGTH = 16.5;
  PENALTY_AREA_WIDTH = 40.32;
  PENALTY_CIRCLE_R = 9.15;
  PENALTY_SPOT_DIST = 11.0;
  GOAL_WIDTH = 14.02;
  GOAL_HALF_WIDTH = GOAL_WIDTH * 0.5;
  GOAL_AREA_LENGTH = 5.5;
  GOAL_AREA_WIDTH = 18.32;
  GOAL_DEPTH = 2.44;
  CORNER_ARC_R = 1.0;
  GOAL_POST_RADIUS = 0.06;
  MIN_FIELD_SCALE = 1.0;
  MAX_FIELD_SCALE = 400.0;
  
  M_canvas_width = -1;
  M_canvas_height = -1;
  M_zoomed = false;
  M_field_scale = 1.0;
  M_field_center_x = 0;
  M_field_center_y = 0;
  return self;
}
- (void) updateFieldSize:(int) canvas_width height:(int) canvas_height{
  M_canvas_width = canvas_width;
  M_canvas_height= canvas_height;
  
  double total_pitch_l = PITCH_LENGTH+PITCH_MARGIN*2.0+1;
  double total_pitch_w = PITCH_WIDTH+PITCH_MARGIN*2.0;
  
  M_field_scale = canvas_width/total_pitch_l;
  int field_height = canvas_height;
  if(total_pitch_w*M_field_scale > field_height){
    M_field_scale = field_height/total_pitch_w;
  }
  if(M_field_scale < MIN_FIELD_SCALE){
    M_field_scale = MIN_FIELD_SCALE;
  }
  
  M_field_center_x = canvas_width/2;
  M_field_center_y = field_height/2;
}

- (int) scale:(double)len{
  return len*M_field_scale;
}

- (int) screenX:(double)x{
  return M_field_center_x + [self scale:x];
}

- (int) screenY:(double)y{
  return M_field_center_y + [self scale:y];
}

- (double) fieldX:(int)x{
  return (x-M_field_center_x)/M_field_scale;
}

- (double) fieldY:(int)y{
  return (y-M_field_center_y)/M_field_scale;
}

- (int) centerX{
  return M_field_center_x;
}

- (int) centerY{
  return M_field_center_y;
}
@end
