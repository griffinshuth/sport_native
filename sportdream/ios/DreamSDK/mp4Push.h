//
//  mp4Push.h
//  sportdream
//
//  Created by lili on 2017/12/22.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface mp4Push : NSObject
-(id)initWithPreview:(UIView*)containerView fileName:(NSString*)fileName fileExtension:(NSString*)fileExtension;
-(void)startPush;
-(void)stopPush;
@end
