//
//  Options.h
//  gameai
//
//  Created by tiankai on 17/6/1.
//  Copyright © 2017年 lili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Options : NSObject
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
