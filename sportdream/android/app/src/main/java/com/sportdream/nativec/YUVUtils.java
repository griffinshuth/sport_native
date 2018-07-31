package com.sportdream.nativec;

/**
 * Created by lili on 2018/4/26.
 */

public class YUVUtils {
    static {
        System.loadLibrary("ndkmain");
    }

    public native void NV21Scale(int big_width,int big_height,byte[] bigdata,int small_width,int small_height,byte[] smalldata);
}
