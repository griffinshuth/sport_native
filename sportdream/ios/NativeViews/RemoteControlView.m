//
//  RemoteControlView.m
//  sportdream
//
//  Created by lili on 2018/3/13.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RemoteControlView.h"
#import "AVFoundation/AVFoundation.h"

@implementation RemoteControlView
-(instancetype)init
{
  if(self = [super init])
  {
    self.hidden = NO;
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    if([self canBecomeFirstResponder]){
      [self becomeFirstResponder];
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    for(UIView* t in self.subviews){
      if([t.class.description isEqualToString:@"MPVolumeSlider"]){
        self.volumeViewSlider = (UISlider*)t;
        break;
      }
    }
    if(self.volumeViewSlider.value == 0 || self.volumeViewSlider.value == 1){
      self.isVolumeChangeInInit = true;
      self.volumeViewSlider.value = 0.5;
    }else{
      self.isVolumeChangeInInit = false;
    }
    self.lastAuto = false;
  }
  return self;
}
-(void)dealloc
{
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
  [self resignFirstResponder];
}

- (BOOL) canBecomeFirstResponder
{
  return YES;
}

-(void)volumeChanged:(NSNotification *)noti
{
  if(self.isVolumeChangeInInit){
    self.isVolumeChangeInInit = false;
    return;
  }
  if(self.lastAuto){
    self.lastAuto = false;
    return;
  }
  CGFloat now_volume = self.volumeViewSlider.value;
  float volume = [[[noti userInfo]objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
  NSLog(@"volumn is %f", volume);
  //这里做你想要的进行的操作
  if(volume>now_volume){
    if(self.onChange){
      self.onChange(@{
                      @"type":@("big")
                      });
    }
  }else{
    if(self.onChange){
      self.onChange(@{
                      @"type":@("small")
                      });
    }
  }
  //已经到达最小或最大
  if(volume == 0){
    self.volumeViewSlider.value = 0.5;
    self.lastAuto = true;
  }else if(volume == 1.0){
    self.volumeViewSlider.value = 0.5;
    self.lastAuto = true;
  }
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
  
  if (receivedEvent.type == UIEventTypeRemoteControl)
    
  {
    switch (receivedEvent.subtype) {
      case UIEventSubtypeRemoteControlTogglePlayPause:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("TogglePlayPause")
                          });
        }
        break;
      case UIEventSubtypeRemoteControlPreviousTrack:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("PreviousTrack")
                          });
        }
        break;
      case UIEventSubtypeRemoteControlNextTrack:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("NextTrack")
                          });
        }
        break;
      case UIEventSubtypeMotionShake:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("MotionShake")
                          });
        }
        break;
      case UIEventSubtypeRemoteControlPlay:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("Play")
                          });
        }
        break;
      case UIEventSubtypeRemoteControlPause:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("Pause")
                          });
        }
        break;
      case UIEventSubtypeRemoteControlStop:
        if(self.onChange){
          self.onChange(@{
                          @"type":@("Stop")
                          });
        }
        break;
      default:
        break;
    }
  }
}
@end
