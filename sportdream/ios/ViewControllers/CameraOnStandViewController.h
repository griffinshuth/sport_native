//
//  CameraOnStandViewController.h
//  sportdream
//
//  Created by lili on 2018/1/9.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraSlowMotionRecord.h"
#import "h264encode.h"
#import "LocalWifiNetwork.h"
#import "MBProgressHUD.h"

@interface H264FrameMetaData : NSObject
@property (nonatomic,assign) int8_t  type;  //帧类型：1代表pps,2 代表sps,3代表I帧，4代表P帧
@property (nonatomic,assign) int64_t absoluteTime;  //绝对时间
@property (nonatomic,assign) int32_t relativeTime;      //相对时间
@property (nonatomic,assign) int32_t frameIndex;        //第几帧
@property (nonatomic,assign) int32_t IFrameIndex;       //p帧对应的I帧位置
@property (nonatomic,assign) int64_t position;          //该帧在文件中的位置，字节为单位
@property (nonatomic,assign) int32_t length;            //该帧的长度，字节为单位
@property (nonatomic,assign) int16_t duration;       //该帧持续时间，毫秒为单位，每一段的第一个I帧持续时间是0
@property (nonatomic,assign) NSData* buffer;         //该帧的内存缓存
@end

enum CameraType
{
  CameraType_MAIN,     //主镜头
  CameraType_BALL,     //跟踪篮球或足球
  CameraType_PART,     //局部赛场镜头
  CameraType_FEATURE,  //人物特写镜头
  CameraType_AUDIENCE, //观众镜头
  CameraType_MOVE,     //移动镜头，无特定功能，比较自由
};

@interface CameraOnStandViewController : UIViewController<CameraSlowMotionRecordDelegate,h264encodeDelegate,LocalWifiNetworkDelegate>
@property (nonatomic,strong) NSString* mDeviceID;
@property (nonatomic,assign) int mRoomID;
@property (nonatomic,strong) NSString* mCameraName;
@property (nonatomic,assign) int mCameraType;
@property (nonatomic,strong) NSString* highlightIP;
@property (nonatomic,assign) BOOL isSlowMotion;
@property (nonatomic,assign) BOOL canAutoGenerateHighlight;
@end
