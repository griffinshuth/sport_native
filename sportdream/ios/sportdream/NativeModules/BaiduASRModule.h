//
//  BaiduASRModule.h
//  sportdream
//
//  Created by lili on 2017/12/5.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "ASR/BDSEventManager.h"
#import "ASR/BDSASRDefines.h"
#import "ASR/BDSASRParameters.h"
#import "TTS/BDSSpeechSynthesizer.h"

@interface BaiduASRModule:RCTEventEmitter <RCTBridgeModule,BDSClientASRDelegate>
@property (strong, nonatomic) BDSEventManager *asrEventManager;
@end
