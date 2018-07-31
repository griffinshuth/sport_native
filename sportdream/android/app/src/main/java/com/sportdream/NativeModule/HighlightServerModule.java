package com.sportdream.NativeModule;

import android.support.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.sportdream.DreamSDK.Delegate.LocalServerModuleDelegate;
import com.sportdream.DreamSDK.HighlightsServerCore;
import com.sportdream.network.LocalClientInfo;
import com.sportdream.network.PacketIDDef;

/**
 * Created by lili on 2018/5/4.
 */

public class HighlightServerModule extends ReactContextBaseJavaModule implements LocalServerModuleDelegate {
    protected ReactApplicationContext context;
    public HighlightServerModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
        HighlightsServerCore.getInstance().registerDelegate(this);
    }
    @Override
    public String getName(){
        return "HighlightServerModule";
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    public void LocalServerModuleListening(){
        WritableMap params = Arguments.createMap();
        sendEvent("onHighlightServerListening",params);
    }
    public void LocalServerModuleRemoteClientAccepted(){}
    public void LocalServerModuleRemoteClientLogined(LocalClientInfo info){
        WritableMap params = Arguments.createMap();
        params.putString("deviceID",info.deviceID);
        sendEvent("onHighlightServerRemoteClientLogined",params);
    }
    public void LocalServerModuleRemoteClientClosed(LocalClientInfo info){
        WritableMap params = Arguments.createMap();
        params.putString("deviceID",info.deviceID);
        sendEvent("onHighlightServerRemoteClientClosed",params);
    }
    public void LocalServerModuleClosed(){
        WritableMap params = Arguments.createMap();
        sendEvent("onHighlightServerClosed",params);
    }
    public void LocalServerModuleRemoteClientDataReceived(String deviceID,String json){
        WritableMap params = Arguments.createMap();
        params.putString("deviceID",deviceID);
        params.putString("json_str",json);
        sendEvent("onHighlightServerDataReceived",params);
    }

    @ReactMethod
    public void startServer(String host,int port){
        HighlightsServerCore.getInstance().startServer(host,port);
    }

    @ReactMethod
    public void stopServer(){
        HighlightsServerCore.getInstance().stopServer();
    }

    @ReactMethod
    public void send(String deviceID,String Message){
        HighlightsServerCore.getInstance().send(deviceID, PacketIDDef.JSON_MESSAGE,Message.getBytes());
    }
}
