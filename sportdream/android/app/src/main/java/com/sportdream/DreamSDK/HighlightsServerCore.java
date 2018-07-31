package com.sportdream.DreamSDK;

import android.util.Log;
import android.view.Surface;

import com.sportdream.DreamSDK.Delegate.LocalServerCoreDelegate;
import com.sportdream.DreamSDK.Delegate.LocalServerModuleDelegate;
import com.sportdream.NativeUI.CameraStandView;
import com.sportdream.network.LocalClientInfo;
import com.sportdream.network.PacketIDDef;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;

/**
 * Created by lili on 2018/5/3.
 */

public class HighlightsServerCore implements LocalServerCoreDelegate {

    private LocalServerCore mServer;
    private HashMap<String,CameraStandView> mCameraStandViews;
    private CameraStandView mHighlightsView;
    LocalServerModuleDelegate mDelegate;

    private HighlightsServerCore(){
        mServer = new LocalServerCore();
        mServer.addDelegate(this);
        mCameraStandViews = new HashMap<>();
    }

    private static final HighlightsServerCore single = new HighlightsServerCore();

    //静态工厂方法
    public static HighlightsServerCore getInstance() {
        return single;
    }

    public void registerDelegate(LocalServerModuleDelegate delegate){
        mDelegate = delegate;
    }

    //delegate
    public void LocalServerListening(){
        mDelegate.LocalServerModuleListening();
    }
    public void LocalServerRemoteClientAccepted(){
        mDelegate.LocalServerModuleRemoteClientAccepted();
    }
    public void LocalServerRemoteClientLogined(LocalClientInfo info){
        mDelegate.LocalServerModuleRemoteClientLogined(info);
    }
    public void LocalServerRemoteClientClosed(LocalClientInfo info){
        mDelegate.LocalServerModuleRemoteClientClosed(info);
        mCameraStandViews.remove(info.deviceID);
    }
    public void LocalServerClosed(){
        mDelegate.LocalServerModuleClosed();
        mCameraStandViews = new HashMap<>();
        mHighlightsView = null;
    }
    public void LocalServerRemoteClientDataReceived(LocalClientInfo info,short PacketID,byte[] data){
        if(PacketID == PacketIDDef.SEND_SMALL_H264SDATA){
            //增加头部
            byte[] framedata = new byte[4+data.length];
            framedata[0] = 0;
            framedata[1] = 0;
            framedata[2] = 0;
            framedata[3] = 1;
            System.arraycopy(data,0,framedata,4,data.length);
            CameraStandH264Decode(info.deviceID,framedata,framedata.length);
        }else{
            if(PacketID == PacketIDDef.JSON_MESSAGE){
                String json_str = new String(data);
                mDelegate.LocalServerModuleRemoteClientDataReceived(info.deviceID,json_str);
            }
        }
    }

    //api
    public void startServer(String host,int port){
        mServer.startServer(host,port);
    }

    public void stopServer(){
        mServer.stopServer();
    }

    public void send(String deviceID,short PacketID,byte[] data){
        mServer.send(deviceID,PacketID,data);
    }

    //显示界面
    public void setHighlightsView(CameraStandView view){
        mHighlightsView = view;
    }

    public void setCameraStandView(String deviceID,CameraStandView view){
        mCameraStandViews.put(deviceID,view);
    }

    public void HighlightsH264Decode(byte[] h264data,int length){
        mHighlightsView.H264Decode(h264data,length);
    }

    public void CameraStandH264Decode(String deviceID,byte[] h264data,int length){
        /*CameraStandView view = mCameraStandViews.get(deviceID);
        if(view != null){
            view.H264Decode(h264data,length);
        }*/
        mHighlightsView.H264Decode(h264data,length);
    }

}
