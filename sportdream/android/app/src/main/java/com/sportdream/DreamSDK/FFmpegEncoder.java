package com.sportdream.DreamSDK;

/**
 * Created by lili on 2018/6/13.
 */

public class FFmpegEncoder {
    static {
        System.loadLibrary("ndkmain");
    }
    long handler;
    private boolean mIsStart;
    private byte[]  h264Buffer;
    public FFmpegEncoder(){
        mIsStart = false;
    }

    public void startEncoder(int width, int height, int fps, int bitrate){
        if(!mIsStart){
            handler = startEncoderNative(width,height,fps,bitrate);
            h264Buffer = new byte[width*height*4];
            mIsStart = true;
        }
    }

    public void stopEncoder(){
        if(mIsStart){
            stopEncoderNative(handler);
            mIsStart = false;
        }
    }

    public byte[] encode(byte[] NV21Data){
        if(!mIsStart){
            return null;
        }
        int length = encodeNative(handler,NV21Data,h264Buffer);
        if(length <= 0){
            //编码失败
            return null;
        }else{
            byte[] result = new byte[length];
            System.arraycopy(h264Buffer,0,result,0,length);
            return result;
        }
    }

    public native long startEncoderNative(int width, int height, int fps, int bitrate);
    public native void stopEncoderNative(long handler);
    public native  int encodeNative(long handler,byte[] NV21Data,byte[] outH264);

}
