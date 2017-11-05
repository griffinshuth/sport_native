//
//  RNTMapManager.m
//  CalendarManager
//
//  Created by lili on 2017/9/11.
//  Copyright © 2017年 lili. All rights reserved.
//

#import "RNTMapManager.h"

@implementation RNTMapManager
RCT_EXPORT_MODULE()

- (UIView*) view
{
    return [[MKMapView alloc] init];
}
@end
