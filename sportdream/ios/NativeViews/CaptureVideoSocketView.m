//
//  CaptureVideoSocketView.m
//  sportdream
//
//  Created by lili on 2018/7/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CaptureVideoSocketView.h"

@implementation CaptureVideoSocketView
{
  CameraSlowMotionRecord* record;
}

-(id)init
{
  self = [super init];
  if(self){
    
  }
  return self;
}

-(void)dealloc
{
  if(record){
    [record stopCapture];
  }
}

- (void)setCapture:(BOOL)capture
{
  if(capture){
    if(!record){
      record = [[CameraSlowMotionRecord alloc] initWithPreview:self isSlowMotion:false];
      record.delegate = self;
      [record startCapture];
    }
  }
}

-(void)captureOutput:(CMSampleBufferRef)sampleBuffer
{
  
}
@end
