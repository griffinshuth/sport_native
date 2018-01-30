//
//  AGAudioBuffer.m
//  sportdream
//
//  Created by lili on 2018/1/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AGAudioBuffer.h"

@implementation AGAudioBuffer
-(instancetype)initWithBuffer:(void*)buffer length:(int)length
{
  if(self = [super init])
  {
    self.buffer = [AGAudioBuffer copy:buffer length:length];
    self.length = length;
    
  }
  return self;
}

+(unsigned char*)copy:(void *)buffer length:(int)length
{
  unsigned char* copyingBuffer = malloc(length);
  memcpy(copyingBuffer, buffer, length);
  return copyingBuffer;
}

-(void)dealloc
{
  free(self.buffer);
}
@end
