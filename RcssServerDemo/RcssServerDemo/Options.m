//
//  Options.m
//  gameai
//
//  Created by tiankai on 17/6/1.
//  Copyright © 2017年 lili. All rights reserved.
//

#import "Options.h"
#import "ConstParameters.h"

@implementation Options
- (id) init{
    self = [super init];
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
