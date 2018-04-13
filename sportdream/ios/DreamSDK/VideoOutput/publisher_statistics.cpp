//
//  publisher_statistics.cpp
//  sportdream
//
//  Created by lili on 2018/3/28.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#include "publisher_statistics.hpp"

PublisherStatistics::PublisherStatistics(float expectedBitRate) {
  this->startTimeMills = platform_4_live::getCurrentTimeMills();
  this->connectTimeMills = -1;
  this->publishDurationInSec = 0;
  this->totalPushVideoFrameCnt = 0;
  this->discardVideoFrameCnt = 0;
  this->publishAVGBitRate = 0;
  this->expectedBitRate = expectedBitRate;
}

PublisherStatistics::~PublisherStatistics() {
}

void PublisherStatistics::connectSuccess(){
  this->connectTimeMills = (int)(platform_4_live::getCurrentTimeMills() - startTimeMills);
}

void PublisherStatistics::discardVideoFrame(int discardVideoPacketSize){
  discardVideoFrameCnt+=discardVideoPacketSize;
}

void PublisherStatistics::pushVideoFrame(){
  totalPushVideoFrameCnt++;
}

char* PublisherStatistics::getAdaptiveBitrateChart(){
  return PublisherRateFeedback::GetInstance()->getAdaptiveBitrateChart();
}

void PublisherStatistics::stopPublish(){
  long publishDurationInTimeMills = platform_4_live::getCurrentTimeMills() - startTimeMills;
  this->publishDurationInSec = (int)(publishDurationInTimeMills / 1000);
  this->expectedBitRate = PublisherRateFeedback::GetInstance()->getCompressedBitRate();
  this->publishAVGBitRate = PublisherRateFeedback::GetInstance()->getPublishedBitRate();
}

