package com.sportdream.network;

import com.koushikdutta.async.AsyncSocket;

import java.util.ArrayList;

/**
 * Created by lili on 2018/4/28.
 */

public class LocalClientInfo {
    public AsyncSocket socket;
    public String      deviceID;
    public SocketBuffer buffer;
    public int          type;
    public String       name;
    public int          state;  //实时画面还是回放画面，0为实时，1为回放,-1为停止播放
    public byte[]       sps;
    public byte[]       pps;
    public ArrayList    playbackMetaData;
    public int          currentPlaybackIndex;

    public LocalClientInfo(){
        socket = null;
        deviceID = "";
        buffer = new SocketBuffer();
        type = -1;
        name = "";
        state = -1;
        sps = null;
        pps = null;
        playbackMetaData = null;
        currentPlaybackIndex = 0;
    }
}
