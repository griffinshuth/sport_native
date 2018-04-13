//
//  publisher_statistics.hpp
//  sportdream
//
//  Created by lili on 2018/3/28.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef publisher_statistics_hpp
#define publisher_statistics_hpp

#include <stdio.h>
#include "platform_4_live_common.h"
#include "publisher_rate_feed_back.hpp"

class PublisherStatistics {
private:
  long                   startTimeMills;
  int                     connectTimeMills;
  int                     publishDurationInSec;
  int                     totalPushVideoFrameCnt;
  int                     discardVideoFrameCnt;
  float                   publishAVGBitRate;
  float                   expectedBitRate;
  
public:
  PublisherStatistics(float expectedBitRate);
  ~PublisherStatistics();
  
  void connectSuccess();
  void discardVideoFrame(int discardVideoPacketSize);
  void pushVideoFrame();
  void stopPublish();
  char* getAdaptiveBitrateChart();
  
  long getStartTimeMills(){
    return startTimeMills;
  };
  
  int getConnectTimeMills(){
    return connectTimeMills;
  };
  
  int getPublishDurationInSec(){
    return publishDurationInSec;
  };
  float getDiscardFrameRatio() {
    if(totalPushVideoFrameCnt > 0){
      return (float) discardVideoFrameCnt / (float) totalPushVideoFrameCnt;
    } else {
      return 0;
    }
  };
  
  float getRealTimePublishBitRate(){
    return PublisherRateFeedback::GetInstance()->getRealTimePublishBitRate();
  };
  
  float getRealTimeCompressedBitRate(){
    return PublisherRateFeedback::GetInstance()->getRealTimeCompressedBitRate();
  };
  
  float getPublishAVGBitRate(){
    return publishAVGBitRate;
  };
  
  float getExpectedBitRate(){
    return expectedBitRate;
  };
};

#endif /* publisher_statistics_hpp */
