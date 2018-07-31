//
//  FootBallStadium.m
//  gameai
//
//  Created by lili on 2017/5/13.
//  Copyright © 2017年 lili. All rights reserved.
//

#import "FootBallStadium.h"
#import "Options.h"

@implementation FootBallStadium
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
    
    CourtInfo* courtInfo;

}

-(id)init{
    self = [super init];
    if(self){
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
        
        courtInfo = nil;

    }
    return self;
}

-(void)setCourtInfo:(CourtInfo*)info
{
    courtInfo = info;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
    CGRect rx = [ UIScreen mainScreen ].bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor (context, 0, 0.5, 0, 1);
    CGContextFillRect (context, CGRectMake (0, 0, rx.size.width, rx.size.height ));
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    
    /*CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGRect cubeRect = CGRectMake(100, 100, 100, 100);
    CGContextAddRect(context, cubeRect);
    CGContextFillPath(context);
    NSString *str = @"哈哈哈哈Good morning hello hi hi hi hi";
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSForegroundColorAttributeName] = [UIColor redColor];
    attrs[NSFontAttributeName] = [UIFont systemFontOfSize:8];
    [str drawInRect:cubeRect withAttributes:attrs];*/
    
    //绘制足球场
    Options* opt = [[Options alloc] init];
    [opt updateFieldSize:rx.size.width height:rx.size.height];
    int left_x = [opt screenX:-PITCH_HALF_LENGTH];
    int right_x = [opt screenX:PITCH_HALF_LENGTH];
    int top_y = [opt screenY:-PITCH_HALF_WIDTH];
    int bottom_y = [opt screenY:PITCH_HALF_WIDTH];
    //绘制边线
    //上边线
    CGContextMoveToPoint(context, left_x, top_y);
    CGContextAddLineToPoint(context, right_x, top_y);
    CGContextStrokePath(context);
    
    //右边线
    CGContextMoveToPoint(context, right_x, top_y);
    CGContextAddLineToPoint(context, right_x, bottom_y);
    CGContextStrokePath(context);
    
    //下边线
    CGContextMoveToPoint(context, right_x, bottom_y);
    CGContextAddLineToPoint(context, left_x, bottom_y);
    CGContextStrokePath(context);
    
    //左边线
    CGContextMoveToPoint(context, left_x, bottom_y);
    CGContextAddLineToPoint(context, left_x, top_y);
    CGContextStrokePath(context);
    
    //绘制中线
    int center_radius = [opt scale:CENTER_CIRCLE_R];
    int center_x = [opt centerX];
    int center_y = [opt centerY];
    CGContextMoveToPoint(context, center_x, top_y);
    CGContextAddLineToPoint(context, center_x, bottom_y);
    CGContextStrokePath(context);
    
    //绘制中圈
    CGContextSetRGBFillColor (context, 1, 0, 0, 0.2);
    CGContextAddArc(context, center_x, center_y, center_radius, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    //绘制左边的大禁区
    int pen_top_y = [opt screenY:-PENALTY_AREA_WIDTH*0.5];
    int pen_bottom_y = [opt screenY:PENALTY_AREA_WIDTH*0.5];
    int pen_x = [opt screenX:-(PITCH_HALF_LENGTH-PENALTY_AREA_LENGTH)];
    int pen_spot_x = [opt screenX:-(PITCH_HALF_LENGTH-PENALTY_SPOT_DIST)];
    
    CGContextMoveToPoint(context, left_x, pen_top_y);
    CGContextAddLineToPoint(context, pen_x, pen_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, pen_x, pen_top_y);
    CGContextAddLineToPoint(context, pen_x, pen_bottom_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, pen_x, pen_bottom_y);
    CGContextAddLineToPoint(context, left_x, pen_bottom_y);
    CGContextStrokePath(context);
    
    //绘制点球点
    CGContextSetRGBFillColor (context, 1, 0, 0, 0.5);
    CGContextAddArc(context, pen_spot_x,center_y, 2, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    //绘制右边的大禁区
    pen_x = [opt screenX:(PITCH_HALF_LENGTH-PENALTY_AREA_LENGTH)];
    pen_spot_x = [opt screenX:(PITCH_HALF_LENGTH-PENALTY_SPOT_DIST)];
    
    CGContextMoveToPoint(context, right_x, pen_top_y);
    CGContextAddLineToPoint(context, pen_x, pen_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, pen_x, pen_top_y);
    CGContextAddLineToPoint(context, pen_x, pen_bottom_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, pen_x, pen_bottom_y);
    CGContextAddLineToPoint(context, right_x, pen_bottom_y);
    CGContextStrokePath(context);
    
    //绘制点球点
    CGContextSetRGBFillColor (context, 1, 0, 0, 0.5);
    CGContextAddArc(context, pen_spot_x,center_y, 2, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    //绘制小禁区
    int goal_area_y_abs = [opt scale:GOAL_AREA_WIDTH*0.5];
    int goal_area_top_y = center_y - goal_area_y_abs;
    int goal_area_bottom_y = center_y+goal_area_y_abs;
    int goal_area_x = [opt screenX:(-PITCH_HALF_LENGTH+GOAL_AREA_LENGTH)];
    
    CGContextMoveToPoint(context, left_x, goal_area_top_y);
    CGContextAddLineToPoint(context, goal_area_x, goal_area_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_area_x, goal_area_top_y);
    CGContextAddLineToPoint(context, goal_area_x, goal_area_bottom_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_area_x, goal_area_bottom_y);
    CGContextAddLineToPoint(context, left_x, goal_area_bottom_y);
    CGContextStrokePath(context);
    
    goal_area_x = [opt screenX:(PITCH_HALF_LENGTH-GOAL_AREA_LENGTH)];
    
    CGContextMoveToPoint(context, right_x, goal_area_top_y);
    CGContextAddLineToPoint(context, goal_area_x, goal_area_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_area_x, goal_area_top_y);
    CGContextAddLineToPoint(context, goal_area_x, goal_area_bottom_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_area_x, goal_area_bottom_y);
    CGContextAddLineToPoint(context, right_x, goal_area_bottom_y);
    CGContextStrokePath(context);

    //绘制球门
    int goal_top_y = [opt screenY:-GOAL_WIDTH*0.5];
    int goal_bottom_y = [opt screenY:GOAL_WIDTH*0.5];
    int goal_x = [opt screenX:-(PITCH_HALF_LENGTH+GOAL_DEPTH)];
    
    CGContextMoveToPoint(context, left_x, goal_top_y);
    CGContextAddLineToPoint(context, goal_x, goal_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_x, goal_bottom_y);
    CGContextAddLineToPoint(context, goal_x, goal_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_x, goal_bottom_y);
    CGContextAddLineToPoint(context, left_x, goal_bottom_y);
    CGContextStrokePath(context);
    
    goal_x = [opt screenX:(PITCH_HALF_LENGTH+GOAL_DEPTH)];
    
    CGContextMoveToPoint(context, right_x, goal_top_y);
    CGContextAddLineToPoint(context, goal_x, goal_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_x, goal_bottom_y);
    CGContextAddLineToPoint(context, goal_x, goal_top_y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, goal_x, goal_bottom_y);
    CGContextAddLineToPoint(context, right_x, goal_bottom_y);
    CGContextStrokePath(context);
    
    if(courtInfo != nil){
        //绘制球员
        int playerCount = (int)[courtInfo.players count];
        for(int i=0;i<playerCount;i++){
            if(courtInfo.players[i].enable){
                double player_x = [opt screenX:courtInfo.players[i].x];
                double player_y = [opt screenY:courtInfo.players[i].y];
                if(courtInfo.players[i].side == 1){
                    CGContextSetRGBFillColor (context, 1, 0, 0, 1);
                }else{
                    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
                }
                CGContextAddArc(context, player_x,player_y, 5, 0, M_PI*2, 0);
                CGContextFillPath(context);
            }
        }
        
        //绘制足球
        double ball_x = [opt screenX:courtInfo.ball.x];
        double ball_y = [opt screenY:courtInfo.ball.y];
        CGContextSetRGBFillColor (context, 0, 1, 0, 1);
        CGContextAddArc(context, ball_x,ball_y, 3, 0, M_PI*2, 0);
        CGContextFillPath(context);
    }
    
    //绘制球员
    //主队
    /*int player_x = [opt screenX:-47.5];
    int player_y = [opt screenY:0];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:-25];
    player_y = [opt screenY:-13];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:-20];
    player_y = [opt screenY:-5];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:-20];
    player_y = [opt screenY:5];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:-25];
    player_y = [opt screenY:13];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:-5];
    player_y = [opt screenY:-8];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:-10];
    player_y = [opt screenY:0];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:-5];
    player_y = [opt screenY:8];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:0];
    player_y = [opt screenY:-18];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:-0.204];
    player_y = [opt screenY:-0.3265];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:0];
    player_y = [opt screenY:18];
    CGContextSetRGBFillColor (context, 0.4, 0, 0, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    //客队
    player_x = [opt screenX:47.5];
    player_y = [opt screenY:0];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:25];
    player_y = [opt screenY:13];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:20];
    player_y = [opt screenY:5];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:20];
    player_y = [opt screenY:-5];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:25];
    player_y = [opt screenY:-13];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:5];
    player_y = [opt screenY:8];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:9];
    player_y = [opt screenY:3];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:5];
    player_y = [opt screenY:-8];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);

    player_x = [opt screenX:1];
    player_y = [opt screenY:10];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:9];
    player_y = [opt screenY:-3];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    player_x = [opt screenX:1];
    player_y = [opt screenY:-10];
    CGContextSetRGBFillColor (context, 0, 0, 1, 1);
    CGContextAddArc(context, player_x,player_y, 3, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    //绘制足球
    int ball_x = [opt screenX:0];
    int ball_y = [opt screenY:0];
    CGContextSetRGBFillColor (context, 0, 0, 0, 1);
    CGContextAddArc(context, ball_x,ball_y, 2, 0, M_PI*2, 0);
    CGContextFillPath(context);*/
    
}



















@end
