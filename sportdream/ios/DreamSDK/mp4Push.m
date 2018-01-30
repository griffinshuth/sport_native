//
//  mp4Push.m
//  sportdream
//
//  Created by lili on 2017/12/22.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "mp4Push.h"
#import <GPUImage/GPUImage.h>

@interface mp4Push()
@property (nonatomic,strong) GPUImageView *filterView;
@property (nonatomic,strong) GPUImageMovie *movieFile;
@property (nonatomic,strong) NSString* fileName;
@property (nonatomic,strong) NSString* fileExtension;
@property (nonatomic, strong) UIView* preview;
@end

@implementation mp4Push
-(id)initWithPreview:(UIView*)containerView fileName:(NSString*)fileName fileExtension:(NSString*)fileExtension
{
  self = [super init];
  if(self){
    self.preview = containerView;
    self.fileName = fileName;
    self.fileExtension = fileExtension;
    self.filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) , CGRectGetHeight([UIScreen mainScreen].bounds))];
    [self.preview addSubview:self.filterView];
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:self.fileName withExtension:self.fileExtension];
    self.movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
    self.movieFile.playAtActualSpeed = YES;
    [self.movieFile addTarget:self.filterView];
  }
  return self;
}
-(void)startPush
{
  [self.movieFile startProcessing];
}
-(void)stopPush
{
  [self.movieFile cancelProcessing];
}
@end
