package com.sportdream.DreamSDK;

import android.view.Surface;

/**
 * Created by lili on 2018/5/12.
 */

public class FFmpegDecoder {
    static {
        System.loadLibrary("ndkmain");
    }
    private int handler;
    private boolean mIsStart;
    public FFmpegDecoder(){
        handler = -1;
        mIsStart = false;
    }
    public void start(final Surface surface, final int width, final int height , int texWidth,int texHeight,byte[] rgbaData){
        if(!mIsStart){
            handler = startNative(width,height,texWidth,texHeight,rgbaData,surface);
            mIsStart = true;
        }
    }

    public void stop(){
        if(mIsStart){
            stopNative(handler);
            mIsStart = false;
        }
    }

    public void DecodeFrame(byte[] h264Data){
        if(mIsStart){
            DecodeFrameNative(handler,h264Data,h264Data.length);
        }
    }

    public native int startNative(int width, int height,int texWidth,int texHeight,byte[] rgbaData, Surface surface);
    public native void stopNative(int handler);
    public native void DecodeFrameNative(int handler,byte[] h264Data,int length);
}
