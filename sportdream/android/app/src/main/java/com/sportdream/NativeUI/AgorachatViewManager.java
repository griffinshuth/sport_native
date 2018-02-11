package com.sportdream.NativeUI;

import android.support.annotation.Nullable;
import android.view.SurfaceView;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.sportdream.Activity.AgoraUtils.AGEventHandler;
import com.sportdream.Activity.AgoraUtils.ConstantApp;
import com.sportdream.Activity.AgoraUtils.EngineConfig;
import com.sportdream.Activity.AgoraUtils.MyEngineEventHandler;
import com.sportdream.Activity.AgoraUtils.WorkerThread;

import io.agora.rtc.Constants;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;

/**
 * Created by lili on 2018/2/9.
 */

public class AgorachatViewManager extends ViewGroupManager<AgoraChatView> implements AGEventHandler {
    private WorkerThread mWorkerThread;
    private ThemedReactContext mContext;
    private String mChannelName = "";
    public AgorachatViewManager(){

    }
    @Override
    public String getName(){
        return "AgorachatView";
    }
    @Override
    public AgoraChatView createViewInstance(ThemedReactContext context){
        mContext = context;
        return new AgoraChatView(context);
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    @ReactProp(name="uid")
    public void setUid(AgoraChatView view,int uid){
        if(uid == 0){

        }else{
            SurfaceView surfaceV = RtcEngine.CreateRendererView(mContext);
            rtcEngine().setupRemoteVideo(new VideoCanvas(surfaceV,VideoCanvas.RENDER_MODE_HIDDEN,uid));
            surfaceV.setZOrderOnTop(true);
            surfaceV.setZOrderMediaOverlay(true);
            view.addView(surfaceV);
        }
    }

    @ReactProp(name="channel")
    public void setChannel(AgoraChatView view,String channel){

        mChannelName = channel;
    }

    @ReactProp(name="status")
    public void setStatus(AgoraChatView view,int status){
        if(status == 0){

        }else if(status == 1){
            if(mChannelName != ""){
                initWorkerThread();
                event().addEventHandler(this);
                String roomName = mChannelName;
                doConfigEngine(Constants.CLIENT_ROLE_BROADCASTER);
                SurfaceView surfaceV = RtcEngine.CreateRendererView(mContext);
                rtcEngine().setupLocalVideo(new VideoCanvas(surfaceV,VideoCanvas.RENDER_MODE_HIDDEN,0));
                surfaceV.setZOrderOnTop(true);
                surfaceV.setZOrderMediaOverlay(true);
                view.addView(surfaceV);
                worker().preview(true,surfaceV,0);
                worker().joinChannel(roomName,config().mUid);
            }
        }else if(status == 2){
            leaveChannel();
            WritableMap params = Arguments.createMap();
            sendEvent("onLeaveChannel",params);
        }
    }

    public void leaveChannel(){
        release();
    }

    private void release(){
        worker().leaveChannel(config().mChannel);
        worker().preview(false,null,0);
        event().removeEventHandler(this);
        deInitWorkerThread();
    }

    public  synchronized void initWorkerThread(){
        if(mWorkerThread == null){
            mWorkerThread = new WorkerThread(mContext);
            mWorkerThread.start();
            mWorkerThread.waitForReady();
        }else{

        }
    }
    public synchronized WorkerThread getWorkerThread() {
        return mWorkerThread;
    }
    public synchronized void deInitWorkerThread(){
        if(mWorkerThread == null){
            return;
        }
        mWorkerThread.exit();
        try {
            mWorkerThread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        mWorkerThread = null;
    }

    private void doConfigEngine(int cRole){
        int prefIndex = ConstantApp.DEFAULT_PROFILE_IDX;
        int vProfile = ConstantApp.VIDEO_PROFILES[prefIndex];
        worker().configEngine(cRole,vProfile);
    }

    protected RtcEngine rtcEngine() {
        return getWorkerThread().getRtcEngine();
    }

    protected final WorkerThread worker() {
        return getWorkerThread();
    }

    protected final EngineConfig config() {
        return getWorkerThread().getEngineConfig();
    }

    protected final MyEngineEventHandler event() {
        return getWorkerThread().eventHandler();
    }

    //delegate
    @Override
    public void onFirstRemoteVideoDecoded(int uid, int width, int height, int elapsed) {

    }

    @Override
    public void onJoinChannelSuccess(final String channel, final int uid, final int elapsed) {

    }

    @Override
    public void onUserOffline(int uid, int reason) {
        WritableMap params = Arguments.createMap();
        params.putInt("uid",uid);
        sendEvent("onUserOffline",params);
    }

    @Override
    public void onUserJoined(int uid, int elapsed) {
        WritableMap params = Arguments.createMap();
        params.putInt("uid",uid);
        sendEvent("onUserJoined",params);
    }
}
