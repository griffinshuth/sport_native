package com.sportdream.network;

import java.nio.ByteBuffer;

/**
 * Created by lili on 2018/5/5.
 */

public class H264FrameMetaData {
    public final static int PPS = 1;
    public final static int SPS = 2;
    public final static int IFRAME = 3;
    public final static int PFRAME = 4;

    public byte type;            //帧类型：1代表pps,2 代表sps,3代表I帧，4代表P帧
    public long absoluteTime;    //绝对时间,毫秒为单位
    public int  relativeTime;    //相对时间,毫秒为单位
    public int  frameIndex;      //第几帧
    public int  IFrameIndex;     //p帧对应的I帧位置
    public long position;        //该帧在文件中的位置，字节为单位
    public int  length;          //该帧的长度，字节为单位
    public short duration;       //该帧持续时间，毫秒为单位，每一段的第一个I帧持续时间是0
    public byte[] buffer;        //该帧的内存缓存

    public H264FrameMetaData(){
        type = -1;
        absoluteTime = -1;
        relativeTime = -1;
        frameIndex = -1;
        IFrameIndex = -1;
        position = -1;
        length = 0;
        duration = 0;
    }

    public static int size(){
        return 1+8+4+4+4+8+4+2;
    }

    public static H264FrameMetaData getH264FrameMetaDataFromBytes(ByteBuffer buffer){
        H264FrameMetaData data = new H264FrameMetaData();
        data.type = buffer.get();
        data.absoluteTime = buffer.getLong();
        data.relativeTime = buffer.getInt();
        data.frameIndex = buffer.getInt();
        data.IFrameIndex = buffer.getInt();
        data.position = buffer.getLong();
        data.length = buffer.getInt();
        data.duration = buffer.getShort();
        return data;
    }

    public static byte[] saveH264FrameMetaDataToBytes(H264FrameMetaData metaData){
        byte[] bytes = new byte[H264FrameMetaData.size()];
        ByteBuffer buffer = ByteBuffer.allocate(H264FrameMetaData.size());
        buffer.put(metaData.type);
        buffer.putLong(metaData.absoluteTime);
        buffer.putInt(metaData.relativeTime);
        buffer.putInt(metaData.frameIndex);
        buffer.putInt(metaData.IFrameIndex);
        buffer.putLong(metaData.position);
        buffer.putInt(metaData.length);
        buffer.putShort(metaData.duration);
        buffer.flip();
        buffer.get(bytes);

        return bytes;
    }
}
