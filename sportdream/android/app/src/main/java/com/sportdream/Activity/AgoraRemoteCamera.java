package com.sportdream.Activity;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.PorterDuff;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewStub;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.os.Handler;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.sportdream.Activity.AgoraUtils.AGEventHandler;
import com.sportdream.Activity.AgoraUtils.ConstantApp;
import com.sportdream.Activity.AgoraUtils.EngineConfig;
import com.sportdream.Activity.AgoraUtils.GridVideoViewContainer;
import com.sportdream.Activity.AgoraUtils.MyEngineEventHandler;
import com.sportdream.Activity.AgoraUtils.SmallVideoViewAdapter;
import com.sportdream.Activity.AgoraUtils.VideoStatusData;
import com.sportdream.Activity.AgoraUtils.VideoViewEventListener;
import com.sportdream.Activity.AgoraUtils.WorkerThread;
import com.sportdream.R;

import java.util.Arrays;
import java.util.HashMap;

import io.agora.rtc.Constants;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;
import io.netty.util.Constant;

/**
 * Created by lili on 2018/1/18.
 */

public class AgoraRemoteCamera extends Activity implements AGEventHandler {
    private GridVideoViewContainer mGridVideoViewContainer;
    private RelativeLayout mSmallVideoViewDock;
    private final HashMap<Integer, SurfaceView> mUidsList = new HashMap<>(); // uid = 0 || uid == EngineConfig.mUid
    public int mViewType = VIEW_TYPE_DEFAULT;
    public static final int VIEW_TYPE_DEFAULT = 0;
    public static final int VIEW_TYPE_SMALL = 1;
    private SmallVideoViewAdapter mSmallVideoViewAdapter;
    //工作线程
    private WorkerThread mWorkerThread;
    public  synchronized void initWorkerThread(){
        if(mWorkerThread == null){
            mWorkerThread = new WorkerThread(getApplicationContext());
            mWorkerThread.start();
            mWorkerThread.waitForReady();
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

    public void initUIandEvent(){
        event().addEventHandler(this);
        String roomName = "test";
        doConfigEngine(Constants.CLIENT_ROLE_BROADCASTER);
        mGridVideoViewContainer = (GridVideoViewContainer)findViewById(R.id.grid_video_view_container);
        mGridVideoViewContainer.setItemEventHandler(new VideoViewEventListener() {
            @Override
            public void onItemDoubleClick(View v, Object item) {
                if(mUidsList.size() <2){
                    return;
                }
                if(mViewType == VIEW_TYPE_DEFAULT){
                    switchToSmallVideoView(((VideoStatusData)item).mUid);
                }else{
                    switchToDefaultVideoView();
                }
            }
        });

        ImageView button1 = (ImageView)findViewById(R.id.btn_1);
        ImageView button2 = (ImageView)findViewById(R.id.btn_2);
        ImageView button3 = (ImageView)findViewById(R.id.btn_3);

        SurfaceView surfaceV = RtcEngine.CreateRendererView(getApplicationContext());
        rtcEngine().setupLocalVideo(new VideoCanvas(surfaceV,VideoCanvas.RENDER_MODE_HIDDEN,0));
        surfaceV.setZOrderOnTop(true);
        surfaceV.setZOrderMediaOverlay(true);
        mUidsList.put(0,surfaceV);
        mGridVideoViewContainer.initViewContainer(getApplicationContext(),0,mUidsList);
        worker().preview(true,surfaceV,0);
        broadcasterUI(button1,button2,button3);
        worker().joinChannel(roomName,config().mUid);
        TextView textRoomName = (TextView)findViewById(R.id.room_name);
        textRoomName.setText(roomName);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        final View layout = findViewById(Window.ID_ANDROID_CONTENT);
        ViewTreeObserver vto = layout.getViewTreeObserver();
        vto.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener(){
            @Override
            public void onGlobalLayout(){
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                    layout.getViewTreeObserver().removeOnGlobalLayoutListener(this);
                } else {
                    layout.getViewTreeObserver().removeGlobalOnLayoutListener(this);
                }
                initWorkerThread();
                initUIandEvent();
            }

        });
        setContentView(R.layout.agora_video_chat);
    }

    private void doConfigEngine(int cRole){
        int prefIndex = ConstantApp.DEFAULT_PROFILE_IDX;
        int vProfile = ConstantApp.VIDEO_PROFILES[prefIndex];
        worker().configEngine(cRole,vProfile);
    }

    private void broadcasterUI(ImageView button1,ImageView button2,ImageView button3){
        button2.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                worker().getRtcEngine().switchCamera();
            }
        });

        button3.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                Object tag = v.getTag();
                boolean flag = true;
                if(tag != null && (boolean)tag){
                    flag = false;
                }
                worker().getRtcEngine().muteLocalAudioStream(flag);
                ImageView button = (ImageView)v;
                button.setTag(flag);
                if (flag) {
                    button.setColorFilter(getResources().getColor(R.color.agora_blue), PorterDuff.Mode.MULTIPLY);
                } else {
                    button.clearColorFilter();
                }
            }
        });
    }

    @Override
    protected void onPostCreate(Bundle savedInstanceState){
        super.onPostCreate(savedInstanceState);
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if(isFinishing()){
                    return;
                }
                boolean checkPermissionResult = checkSelfPermissions();
                if ((Build.VERSION.SDK_INT < Build.VERSION_CODES.M)) {
                    // so far we do not use OnRequestPermissionsResultCallback
                }
            }
        },500);
    }

    protected void deInitUIandEvent(){
        doLeaveChannel();
        event().removeEventHandler(this);
        mUidsList.clear();
    }

    private void doLeaveChannel(){
        worker().leaveChannel(config().mChannel);
        worker().preview(false,null,0);
    }

    public void onClickClose(View v){finish();}

    @Override
    protected void onDestroy(){
        deInitUIandEvent();
        deInitWorkerThread();
        super.onDestroy();
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

    public final void showLongToast(final String msg) {
        this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(getApplicationContext(), msg, Toast.LENGTH_LONG).show();
            }
        });
    }

    private boolean checkSelfPermissions() {
        return checkSelfPermission(Manifest.permission.RECORD_AUDIO, ConstantApp.PERMISSION_REQ_ID_RECORD_AUDIO) &&
                checkSelfPermission(Manifest.permission.CAMERA, ConstantApp.PERMISSION_REQ_ID_CAMERA) &&
                checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, ConstantApp.PERMISSION_REQ_ID_WRITE_EXTERNAL_STORAGE);
    }

    public boolean checkSelfPermission(String permission, int requestCode) {
        if (ContextCompat.checkSelfPermission(this,
                permission)
                != PackageManager.PERMISSION_GRANTED) {

            ActivityCompat.requestPermissions(this,
                    new String[]{permission},
                    requestCode);
            return false;
        }
        if (Manifest.permission.CAMERA.equals(permission)) {
            //initWorkerThread();
        }
        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           @NonNull String permissions[], @NonNull int[] grantResults) {
                switch (requestCode) {
            case ConstantApp.PERMISSION_REQ_ID_RECORD_AUDIO: {
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    checkSelfPermission(Manifest.permission.CAMERA, ConstantApp.PERMISSION_REQ_ID_CAMERA);
                } else {
                    finish();
                }
                break;
            }
            case ConstantApp.PERMISSION_REQ_ID_CAMERA: {
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, ConstantApp.PERMISSION_REQ_ID_WRITE_EXTERNAL_STORAGE);
                    //initWorkerThread();
                } else {
                    finish();
                }
                break;
            }
            case ConstantApp.PERMISSION_REQ_ID_WRITE_EXTERNAL_STORAGE: {
                if (grantResults.length > 0
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                } else {
                    finish();
                }
                break;
            }
        }
    }

    private void doRenderRemoteUi(final int uid){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(isFinishing()){
                    return;
                }
                SurfaceView surfaceV = RtcEngine.CreateRendererView(getApplicationContext());
                surfaceV.setZOrderOnTop(true);
                surfaceV.setZOrderMediaOverlay(true);
                mUidsList.put(uid,surfaceV);
                if(config().mUid == uid){
                    rtcEngine().setupLocalVideo(new VideoCanvas(surfaceV,VideoCanvas.RENDER_MODE_HIDDEN,uid));
                }else{
                    rtcEngine().setupRemoteVideo(new VideoCanvas(surfaceV,VideoCanvas.RENDER_MODE_HIDDEN,uid));
                }
                if(mViewType == VIEW_TYPE_DEFAULT){
                    switchToDefaultVideoView();
                }else{
                    int bigBgUid = mSmallVideoViewAdapter.getExceptedUid();
                    switchToSmallVideoView(bigBgUid);
                }
            }
        });
    }

    private void doRemoveRemoteUi(final int uid){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(isFinishing()){
                    return;
                }
                mUidsList.remove(uid);

                int bigBgUid = -1;
                if(mSmallVideoViewAdapter != null){
                    bigBgUid = mSmallVideoViewAdapter.getExceptedUid();
                }
                if(mViewType == VIEW_TYPE_DEFAULT || uid == bigBgUid){
                    switchToDefaultVideoView();
                }else{
                    switchToSmallVideoView(bigBgUid);
                }
            }
        });
    }

    @Override
    public void onFirstRemoteVideoDecoded(int uid, int width, int height, int elapsed) {

    }

    @Override
    public void onJoinChannelSuccess(final String channel, final int uid, final int elapsed) {

    }

    @Override
    public void onUserOffline(int uid, int reason) {
        doRemoveRemoteUi(uid);
    }

    @Override
    public void onUserJoined(int uid, int elapsed) {
        doRenderRemoteUi(uid);
    }

    private void requestRemoteStreamType(){
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                HashMap.Entry<Integer,SurfaceView> highest = null;
                for (HashMap.Entry<Integer, SurfaceView> pair : mUidsList.entrySet()) {
                    if (pair.getKey() != config().mUid && (highest == null || highest.getValue().getHeight() < pair.getValue().getHeight())) {
                        if (highest != null) {
                            rtcEngine().setRemoteVideoStreamType(highest.getKey(), Constants.VIDEO_STREAM_LOW);
                        }
                        highest = pair;
                    } else if (pair.getKey() != config().mUid && (highest != null && highest.getValue().getHeight() >= pair.getValue().getHeight())) {
                        rtcEngine().setRemoteVideoStreamType(pair.getKey(), Constants.VIDEO_STREAM_LOW);
                    }
                }
                if(highest != null && highest.getKey() != 0){
                    rtcEngine().setRemoteVideoStreamType(highest.getKey(),Constants.VIDEO_STREAM_HIGH);
                }
            }
        },500);
    }

    private void bindToSmallVideoView(int exceptUid){
        if(mSmallVideoViewDock == null){
            ViewStub stub = (ViewStub)findViewById(R.id.small_video_view_dock);
            mSmallVideoViewDock = (RelativeLayout)stub.inflate();
        }
        RecyclerView recycler = (RecyclerView)findViewById(R.id.small_video_view_container);
        boolean create = false;
        if(mSmallVideoViewAdapter == null){
            create = true;
            mSmallVideoViewAdapter = new SmallVideoViewAdapter(this, exceptUid, mUidsList, new VideoViewEventListener() {
                @Override
                public void onItemDoubleClick(View v, Object item) {
                    switchToDefaultVideoView();
                }
            });
            mSmallVideoViewAdapter.setHasStableIds(true);
        }
        recycler.setHasFixedSize(true);
        recycler.setLayoutManager(new GridLayoutManager(this,3,GridLayoutManager.VERTICAL,false));
        recycler.setAdapter(mSmallVideoViewAdapter);
        recycler.setDrawingCacheEnabled(true);
        recycler.setDrawingCacheQuality(View.DRAWING_CACHE_QUALITY_AUTO);
        if(!create){
            mSmallVideoViewAdapter.notifyUiChanged(mUidsList,exceptUid,null,null);
        }
        recycler.setVisibility(View.VISIBLE);
        mSmallVideoViewDock.setVisibility(View.VISIBLE);
    }

    private void switchToDefaultVideoView(){
        if(mSmallVideoViewDock != null){
            mSmallVideoViewDock.setVisibility(View.GONE);
        }
        mGridVideoViewContainer.initViewContainer(getApplicationContext(),config().mUid,mUidsList);
        mViewType = VIEW_TYPE_DEFAULT;
        int sizeLimit = mUidsList.size();
        for(int i=0;i<sizeLimit;i++){
            int uid = mGridVideoViewContainer.getItem(i).mUid;
            if(config().mUid != uid){
                rtcEngine().setRemoteVideoStreamType(uid,Constants.VIDEO_STREAM_HIGH);
            }
        }
    }

    private void switchToSmallVideoView(int uid){
        HashMap<Integer,SurfaceView> slice = new HashMap<>(1);
        slice.put(uid,mUidsList.get(uid));
        mGridVideoViewContainer.initViewContainer(getApplicationContext(),uid,slice);
        bindToSmallVideoView(uid);
        mViewType = VIEW_TYPE_SMALL;
        requestRemoteStreamType();
    }

}



















































