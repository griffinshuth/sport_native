//
//  CalendarManager.m
//  CalendarManager
//
//  Created by lili on 2017/9/9.
//  Copyright © 2017年 lili. All rights reserved.
//

#import "CalendarManager.h"

@implementation CalendarManager
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(addEvent:(NSString *)name location:(NSString *)location)
{
    RCTLogInfo(@"Pretending to create an event %@ at %@", name, location);
}

RCT_EXPORT_METHOD(findEvents:(RCTResponseSenderBlock)callback)
{
    NSArray* events = [NSArray arrayWithObjects:@"one",@"two",@1, nil];
    callback(@[[NSNull null],events]);
}

RCT_REMAP_METHOD(getCalendar, resolver:(RCTPromiseResolveBlock)resolve
                               rejecter:(RCTPromiseRejectBlock)reject)
{
    
    NSDictionary* error = [NSDictionary dictionaryWithObjects:@[@"1"] forKeys:@[@"error"]];
    NSArray* events = [NSArray arrayWithObjects:@"one",@"two",@1,error, nil];
    NSError * err=[NSError errorWithDomain:@"test" code:0 userInfo:nil];
    if(events){
        resolve(events);
    }else{
        reject(@"0",@"cancel",err);
    }
}

- (NSDictionary*) constantsToExport
{
    return @{@"TeamSize":@"12"};
}

@end
