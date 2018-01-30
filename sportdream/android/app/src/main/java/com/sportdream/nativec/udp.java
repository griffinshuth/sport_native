package com.sportdream.nativec;

/**
 * Created by lili on 2017/12/26.
 */

public class udp {
    static {
        System.loadLibrary("main");
    }

    public native void init(short port);
    public native void close();
    public native void sendto(String ip,short port,byte[] data);
    public native byte[] recvfrom();
}
