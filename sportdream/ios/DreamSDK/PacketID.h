//
//  PacketID.h
//  sportdream
//
//  Created by lili on 2018/1/15.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef PacketID_h
#define PacketID_h

typedef enum PACKET_ID{
  START_SEND_BIGDATA = 1,
  STOP_SEND_BIGDATA = 2,
  START_SEND_SMALLDATA = 3,
  STOP_SEND_SMALLDATA = 4,
  SEND_BIG_H264DATA = 5,
  SEND_SMALL_H264SDATA = 6,
  CAMERA_NAME = 7,
  COMMENT_AUDIO = 8,
  JSON_MESSAGE = 9
}PACKET_ID;

enum FRAMETYPE{
  H264FRAMETYPE_PPS = 1,
  H264FRAMETYPE_SPS = 2,
  H264FRAMETYPE_IFRAME = 3,
  H264FRAMETYPE_PFRAME = 4
};

#endif /* PacketID_h */
