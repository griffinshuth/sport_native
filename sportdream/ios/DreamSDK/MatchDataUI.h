//
//  MatchDataUI.h
//  sportdream
//
//  Created by lili on 2018/6/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MatchDataUI : NSObject
+(UIImageView*)createBase64Image:(NSString*)base64String width:(int)width height:(int)height;
+(UIImageView*)createImageOfUrl:(NSString*)imageUrl width:(int)width height:(int)height;
+(UIView*)createCourtDataView:(NSDictionary*)gameData;
+(int)TechnicalStatisticsOfIDWithType:(NSString*)type uid:(NSString*)uid gameData:(NSDictionary*)gameData teamindex:(int)teamindex;
@end
