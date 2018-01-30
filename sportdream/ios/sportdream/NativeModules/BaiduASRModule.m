//
//  BaiduASRModule.m
//  sportdream
//
//  Created by lili on 2017/12/5.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "BaiduASRModule.h"
#import <AVFoundation/AVFoundation.h>
const NSString* API_KEY = @"agdSsATufjGfa7k4spfO1Tuu";
const NSString* SECRET_KEY = @"ipSsHYAgCkfNiguBGhEyySGa9h2empaZ";
const NSString* APP_ID = @"10484367";

@implementation BaiduASRModule
RCT_EXPORT_MODULE(BaiduASRModule);

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onVoiceRecognize"];
}

- (id) init
{
  self = [super init];
  if(!self) return nil;
  NSString* gramm_filepath = [[NSBundle mainBundle] pathForResource:@"baidu_speech_grammar" ofType:@"bsg"];
  NSString* lm_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];;
  NSString* wakeup_words_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_wakeup_words" ofType:@"dat"];;
  self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
  // 设置语音识别代理
  [self.asrEventManager setDelegate:self];
  // 参数配置：在线身份验证
  [self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
  //设置 APPID
  [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
  
  /*// 参数设置：识别策略为离在线并行
  [self.asrEventManager setParameter:@(EVR_STRATEGY_BOTH) forKey:BDS_ASR_STRATEGY];
  // 参数设置：离线识别引擎类型
  [self.asrEventManager setParameter:@(EVR_OFFLINE_ENGINE_GRAMMER) forKey:BDS_ASR_OFFLINE_ENGINE_TYPE];
  
  [self.asrEventManager setParameter:lm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_DAT_FILE_PATH];
  // 请在 (官网)[http://speech.baidu.com/asr] 参考模板定义语法，下载语法文件后，替换BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH参数
  [self.asrEventManager setParameter:gramm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH];
  [self.asrEventManager setParameter:wakeup_words_filepath forKey:BDS_ASR_OFFLINE_ENGINE_WAKEUP_WORDS_FILE_PATH];
  // 发送指令：加载离线引擎
  [self.asrEventManager sendCommand:BDS_ASR_CMD_LOAD_ENGINE];*/
  
   [self configVoiceRecognitionClient];
  
  //TTS
  //[BDSSpeechSynthesizer setLogLevel:BDS_PUBLIC_LOG_VERBOSE];
  [[BDSSpeechSynthesizer sharedInstance] setSynthesizerDelegate:self];
  [self configureOnlineTTS];
  [self configureOfflineTTS];
  return self;
}

-(void)configureOnlineTTS{
  
  [[BDSSpeechSynthesizer sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
  [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(NO) forKey:BDS_SYNTHESIZER_PARAM_ENABLE_AVSESSION_MGMT];
  [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
  [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(BDS_SYNTHESIZER_SPEAKER_DYY) forKey:BDS_SYNTHESIZER_PARAM_SPEAKER];
  //    [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(10) forKey:BDS_SYNTHESIZER_PARAM_ONLINE_REQUEST_TIMEOUT];
  
}

-(void)configureOfflineTTS{
  
  NSError *err = nil;
  NSString* offlineEngineSpeechData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Speech_Male" ofType:@"dat"];
  NSString* offlineChineseAndEnglishTextData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Text" ofType:@"dat"];
  
  err = [[BDSSpeechSynthesizer sharedInstance] loadOfflineEngine:offlineChineseAndEnglishTextData speechDataPath:offlineEngineSpeechData licenseFilePath:nil withAppCode:APP_ID];
  if(err){
    NSLog(@"Offline TTS init failed");
    return;
  }

}

- (NSString *)getDescriptionForDic:(NSDictionary *)dic {
  if (dic) {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
                                                                          options:NSJSONWritingPrettyPrinted
                                                                            error:nil] encoding:NSUTF8StringEncoding];
  }
  return nil;
}

- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {

  switch (workStatus) {
    case EVoiceRecognitionClientWorkStatusFinish: {
      if (aObj) {
        NSString* text = [self getDescriptionForDic:aObj];
        NSLog(@"%@",text);
        [self sendEventWithName:@"onVoiceRecognize" body:@{@"data": text}];
      }
      break;
    }
    case EVoiceRecognitionClientWorkStatusStart: {
      NSLog(@"CALLBACK: detect voice start point.\n");
      break;
    }
    case EVoiceRecognitionClientWorkStatusEnd: {
      NSLog(@"CALLBACK: detect voice end point.\n");
      break;
    }
    case EVoiceRecognitionClientWorkStatusRecorderEnd: {
      NSLog(@"CALLBACK: recorder closed.\n");
      break;
    }
    case EVoiceRecognitionClientWorkStatusFlushData: {
      NSLog(@"CALLBACK: partial result - %@.\n\n", [self getDescriptionForDic:aObj]);
      break;
    }
  }
}

- (void)configVoiceRecognitionClient {
  //设置DEBUG_LOG的级别
  [self.asrEventManager setParameter:@(EVRDebugLogLevelTrace) forKey:BDS_ASR_DEBUG_LOG_LEVEL];
  //配置端点检测（二选一）
  //[self configModelVAD];
    [self configDNNMFE];
}

- (void)configModelVAD {
  NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
  [self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
  [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
}

- (void)configDNNMFE {
  NSString *mfe_dnn_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_mfe_dnn" ofType:@"dat"];
  [self.asrEventManager setParameter:mfe_dnn_filepath forKey:BDS_ASR_MFE_DNN_DAT_FILE];
  NSString *cmvn_dnn_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_mfe_cmvn" ofType:@"dat"];
  [self.asrEventManager setParameter:cmvn_dnn_filepath forKey:BDS_ASR_MFE_CMVN_DAT_FILE];
  // 自定义静音时长
      [self.asrEventManager setParameter:@(51) forKey:BDS_ASR_MFE_MAX_SPEECH_PAUSE];
      [self.asrEventManager setParameter:@(10) forKey:BDS_ASR_MFE_MAX_WAIT_DURATION];
}

RCT_EXPORT_METHOD(ASRInit)
{
  self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
  // 设置语音识别代理
  [self.asrEventManager setDelegate:self];
  // 参数配置：在线身份验证
  [self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
  //设置 APPID
  [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
  
  [self configVoiceRecognitionClient];
}

RCT_EXPORT_METHOD(startListen)
{
  [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_NEED_CACHE_AUDIO];
  [self.asrEventManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
  [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
  // 长语音请务必开启本地VAD
  [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LOCAL_VAD];
  
  [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
}

RCT_EXPORT_METHOD(endListen){
  [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
}

RCT_EXPORT_METHOD(brightness:(float)bright)
{
  [UIScreen mainScreen].brightness = bright;
}

RCT_EXPORT_METHOD(getBrightness:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSNumber *myNumber = [NSNumber numberWithDouble:[UIScreen mainScreen].brightness];
  resolve(@{@"brightness": myNumber});
}

RCT_EXPORT_METHOD(speak:(NSString*)text)
{
  [[BDSSpeechSynthesizer sharedInstance] speakSentence:text withError:nil];
}
@end




























