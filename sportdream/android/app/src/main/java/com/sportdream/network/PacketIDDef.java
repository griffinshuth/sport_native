package com.sportdream.network;

/**
 * Created by lili on 2018/5/3.
 */

public class PacketIDDef {
    public static final short START_SEND_BIGDATA = 1;
    public static final short STOP_SEND_BIGDATA = 2;
    public static final short START_SEND_SMALLDATA = 3;
    public static final short STOP_SEND_SMALLDATA = 4;
    public static final short SEND_BIG_H264DATA = 5;
    public static final short SEND_SMALL_H264SDATA = 6;
    public static final short CAMERA_NAME = 7;
    public static final short COMMENT_AUDIO = 8;
    public static final short JSON_MESSAGE = 9;
}
