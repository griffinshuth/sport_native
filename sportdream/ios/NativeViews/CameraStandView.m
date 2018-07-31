//
//  HighlightView.m
//  sportdream
//
//  Created by lili on 2018/5/23.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CameraStandView.h"

@implementation CameraStandView
-(id)init
{
  self = [super init];
  if(self){
    self.decoder = [[h264decode alloc] initWithView:self previewWidth:320 previewHeight:180];
  }
  return self;
}

-(void)dealloc
{
  
}

- (void)setUid:(NSNumber *)uid
{
  self.uid = uid;
}
@end
