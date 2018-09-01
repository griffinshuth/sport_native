package com.sportdream.Activity.AgoraUtils;

import android.content.Context;
import android.content.SharedPreferences;
import android.media.audiofx.BassBoost;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.preference.PreferenceManager;
import android.provider.Settings;
import android.util.Log;
import android.view.SurfaceView;

import java.io.File;

import io.agora.rtc.Constants;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;

/**
 * Created by lili on 2018/1/18.
 */

public class WorkerThread extends Thread {
    private RtcEngine mRtcEngine;
    private EngineConfig mEngineConfig;
    private final Context mContext;
    private static final int ACTION_WORKER_THREAD_QUIT = 0X1010; // quit this thread

    private static final int ACTION_WORKER_JOIN_CHANNEL = 0X2010;

    private static final int ACTION_WORKER_LEAVE_CHANNEL = 0X2011;

    private static final int ACTION_WORKER_CONFIG_ENGINE = 0X2012;

    private static final int ACTION_WORKER_PREVIEW = 0X2014;

    public WorkerThread(Context context){
        this.mContext = context;
        this.mEngineConfig = new EngineConfig();
        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(context);
        this.mEngineConfig.mUid = pref.getInt(ConstantApp.PrefManager.PREF_PROPERTY_UID, 0);

        this.mEngineEventHandler = new MyEngineEventHandler(mContext, this.mEngineConfig);
    }

    private static final class WorkerThreadHandler extends Handler{
        private WorkerThread mWorkerThread;
        WorkerThreadHandler(WorkerThread thread){
            this.mWorkerThread = thread;
        }
        public void release(){
            mWorkerThread = null;
        }

        @Override
        public void handleMessage(Message msg){
            if(this.mWorkerThread == null){
                return;
            }
            switch (msg.what){
                case ACTION_WORKER_THREAD_QUIT:
                    mWorkerThread.exit();
                    break;
                case ACTION_WORKER_JOIN_CHANNEL:
                    String[] data = (String[]) msg.obj;
                    mWorkerThread.joinChannel(data[0], msg.arg1);
                    break;
                case ACTION_WORKER_LEAVE_CHANNEL:
                    String channel = (String) msg.obj;
                    mWorkerThread.leaveChannel(channel);
                    break;
                case ACTION_WORKER_CONFIG_ENGINE:
                    Object[] configData = (Object[]) msg.obj;
                    mWorkerThread.configEngine((int) configData[0], (int) configData[1]);
                    break;
                case ACTION_WORKER_PREVIEW:
                    Object[] previewData = (Object[]) msg.obj;
                    mWorkerThread.preview((boolean) previewData[0], (SurfaceView) previewData[1], (int) previewData[2]);
                    break;
            }
        }
    }

    private WorkerThreadHandler mWorkerHandler;
    private boolean mReady;
    public final void waitForReady(){
        while (!mReady){
            try {
                Thread.sleep(20);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            Log.d("sportdream","wait for " + WorkerThread.class.getSimpleName());
        }
    }

    @Override
    public void run(){
        Looper.prepare();
        mWorkerHandler = new WorkerThreadHandler(this);
        ensureRtcEngineReadyLock();
        mReady = true;
        Looper.loop();
    }

    public final void joinChannel(final String channel,int uid){
        if(Thread.currentThread() != this){
            Message envelop = new Message();
            envelop.what = ACTION_WORKER_JOIN_CHANNEL;
            envelop.obj = new String[]{channel};
            envelop.arg1 = uid;
            mWorkerHandler.sendMessage(envelop);
            return;
        }
        ensureRtcEngineReadyLock();
        mRtcEngine.joinChannel(null,channel,"mangguo",uid);
        mEngineConfig.mChannel = channel;
    }

    public final void leaveChannel(String channel){
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = ACTION_WORKER_LEAVE_CHANNEL;
            envelop.obj = channel;
            mWorkerHandler.sendMessage(envelop);
            return;
        }

        if (mRtcEngine != null) {
            mRtcEngine.leaveChannel();
        }

        mEngineConfig.reset();
    }

    public final EngineConfig getEngineConfig() {
        return mEngineConfig;
    }

    private final MyEngineEventHandler mEngineEventHandler;

    public final void configEngine(int cRole, int vProfile) {
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = ACTION_WORKER_CONFIG_ENGINE;
            envelop.obj = new Object[]{cRole, vProfile};
            mWorkerHandler.sendMessage(envelop);
            return;
        }

        ensureRtcEngineReadyLock();
        mEngineConfig.mClientRole = cRole;
        mEngineConfig.mVideoProfile = vProfile;

        mRtcEngine.setVideoProfile(mEngineConfig.mVideoProfile, false);

        mRtcEngine.setClientRole(cRole, "");
    }

    public final void preview(boolean start, SurfaceView view, int uid) {
        if (Thread.currentThread() != this) {
            Message envelop = new Message();
            envelop.what = ACTION_WORKER_PREVIEW;
            envelop.obj = new Object[]{start, view, uid};
            mWorkerHandler.sendMessage(envelop);
            return;
        }

        ensureRtcEngineReadyLock();
        if (start) {
            mRtcEngine.setupLocalVideo(new VideoCanvas(view, VideoCanvas.RENDER_MODE_HIDDEN, uid));
            mRtcEngine.startPreview();
        } else {
            mRtcEngine.stopPreview();
        }
    }

    public static String getDeviceID(Context context){
        return Settings.Secure.getString(context.getContentResolver(),Settings.Secure.ANDROID_ID);
    }

    private RtcEngine ensureRtcEngineReadyLock() {
        if(mRtcEngine == null){
            try {
                mRtcEngine = RtcEngine.create(mContext, "b46966ee5e7e493496a97ddf6f19b87f", mEngineEventHandler.mRtcEventHandler);
            } catch (Exception e) {
                throw new RuntimeException("NEED TO check rtc sdk init fatal error\n" + Log.getStackTraceString(e));
            }
            mRtcEngine.setChannelProfile(Constants.CHANNEL_PROFILE_LIVE_BROADCASTING);
            mRtcEngine.enableVideo();
            mRtcEngine.muteLocalAudioStream(true);
            mRtcEngine.setLogFile(Environment.getExternalStorageDirectory()
                    + File.separator + mContext.getPackageName() + "/log/agora-rtc.log");
            mRtcEngine.enableDualStreamMode(true);
        }
        return mRtcEngine;
    }

    public MyEngineEventHandler eventHandler() {
        return mEngineEventHandler;
    }

    public RtcEngine getRtcEngine() {
        return mRtcEngine;
    }

    public final void exit(){
        if(Thread.currentThread() != this){
            mWorkerHandler.sendEmptyMessage(ACTION_WORKER_THREAD_QUIT);
            return;
        }
        mReady = false;
        Looper.myLooper().quit();
        mWorkerHandler.release();
    }
}











































