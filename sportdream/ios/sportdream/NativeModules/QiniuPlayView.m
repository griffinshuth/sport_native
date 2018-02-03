#import "QiniuPlayView.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>

@implementation QiniuPlayView{
  RCTEventDispatcher *_eventDispatcher;
  //PLPlayer *_plplayer;
  bool _started;
  bool _muted;
}

static NSString *status[] = {
  @"PLPlayerStatusUnknow",
  @"PLPlayerStatusPreparing",
  @"PLPlayerStatusReady",
  @"PLPlayerStatusCaching",
  @"PLPlayerStatusPlaying",
  @"PLPlayerStatusPaused",
  @"PLPlayerStatusStopped",
  @"PLPlayerStatusError"
};


- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  if ((self = [super init])) {
    _eventDispatcher = eventDispatcher;
    _started = YES;
    _muted = NO;
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.reconnectCount = 0;
  }
  
  return self;
};

- (void) setSource:(NSDictionary *)source
{
  /*NSString *uri = source[@"uri"];
  bool backgroundPlay = source[@"backgroundPlay"] == nil ? false : source[@"backgroundPlay"];
  
  PLPlayerOption *option = [PLPlayerOption defaultOption];
  
  // 更改需要修改的 option 属性键所对应的值
  [option setOptionValue:@15 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];
  
  if(_plplayer){
    [_plplayer stop]; //TODO View 被卸载时 也要调用
  }
  
  _plplayer = [PLPlayer playerWithURL:[[NSURL alloc] initWithString:uri] option:option];
  
  _plplayer.delegate = self;
  _plplayer.delegateQueue = dispatch_get_main_queue();
  _plplayer.backgroundPlayEnable = backgroundPlay;
  if(backgroundPlay){
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startPlayer) name:UIApplicationWillEnterForegroundNotification object:nil];
  }
  [self setupUI];
  
  [self startPlayer];*/
  
}

- (void)setupUI {
  /*if (_plplayer.status != PLPlayerStatusError) {
    // add player view
    UIView *playerView = _plplayer.playerView;
    [self addSubview:playerView];
    [playerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:playerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    NSArray *constraints = [NSArray arrayWithObjects:centerX, centerY,width,height, nil];
    [self addConstraints: constraints];
  }*/
  
}

- (void) setStarted:(BOOL) started{
  /*if(started != _started){
    if(started){
      [_plplayer resume];
      _started = started;
    }else{
      [_plplayer pause];
      _started = started;
    }
  }*/
}

- (void) setMuted:(BOOL) muted {
  /*_muted = muted;
  [_plplayer setMute:muted];*/
  
}

- (void)startPlayer {
  [UIApplication sharedApplication].idleTimerDisabled = YES;
  //[_plplayer play];
  _started = true;
}



@end
