package com.sportdream.Activity.AgoraUtils;

import android.content.Context;

import java.util.Iterator;
import java.util.concurrent.ConcurrentHashMap;

import io.agora.rtc.IRtcEngineEventHandler;

/**
 * Created by lili on 2018/1/18.
 */

public class MyEngineEventHandler {
    private final EngineConfig mConfig;
    private final Context mContext;
    private final ConcurrentHashMap<AGEventHandler,Integer> mEventHandlerList = new ConcurrentHashMap<>();

    public MyEngineEventHandler(Context ctx,EngineConfig config){
        this.mContext = ctx;
        this.mConfig = config;
    }

    public void addEventHandler(AGEventHandler handler){
        this.mEventHandlerList.put(handler,0);
    }

    public void removeEventHandler(AGEventHandler handler){
        this.mEventHandlerList.remove(handler);
    }

    final IRtcEngineEventHandler mRtcEventHandler = new IRtcEngineEventHandler() {
        @Override
        public void onFirstRemoteVideoDecoded(int uid, int width, int height, int elapsed) {
            Iterator<AGEventHandler> it = mEventHandlerList.keySet().iterator();
            while (it.hasNext()) {
                AGEventHandler handler = it.next();
                handler.onFirstRemoteVideoDecoded(uid, width, height, elapsed);
            }
        }

        @Override
        public void onFirstLocalVideoFrame(int width, int height, int elapsed) {

        }

        @Override
        public void onUserJoined(int uid, int elapsed) {
            Iterator<AGEventHandler> it = mEventHandlerList.keySet().iterator();
            while (it.hasNext()) {
                AGEventHandler handler = it.next();
                handler.onUserJoined(uid, elapsed);
            }
        }

        @Override
        public void onUserOffline(int uid, int reason) {
            // FIXME this callback may return times
            Iterator<AGEventHandler> it = mEventHandlerList.keySet().iterator();
            while (it.hasNext()) {
                AGEventHandler handler = it.next();
                handler.onUserOffline(uid, reason);
            }
        }

        @Override
        public void onUserMuteVideo(int uid, boolean muted) {
        }

        @Override
        public void onRtcStats(RtcStats stats) {
        }


        @Override
        public void onLeaveChannel(RtcStats stats) {

        }

        @Override
        public void onLastmileQuality(int quality) {

        }

        @Override
        public void onError(int err) {
            super.onError(err);
        }

        @Override
        public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
            Iterator<AGEventHandler> it = mEventHandlerList.keySet().iterator();
            while (it.hasNext()) {
                AGEventHandler handler = it.next();
                handler.onJoinChannelSuccess(channel, uid, elapsed);
            }
        }

        public void onRejoinChannelSuccess(String channel, int uid, int elapsed) {

        }

        public void onWarning(int warn) {

        }
    };
}
