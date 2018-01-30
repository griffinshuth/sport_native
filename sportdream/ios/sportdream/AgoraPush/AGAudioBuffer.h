//
//  AGAudioBuffer.h
//  sportdream
//
//  Created by lili on 2018/1/2.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGAudioBuffer : NSObject
@property (assign,nonatomic)void* buffer;
@property (assign,nonatomic)int length;

-(instancetype)initWithBuffer:(void*)buffer length:(int)length;
+(unsigned char*)copy:(void*)buffer length:(int)length;
@end
