package com.sportdream.NativeModule;

import android.support.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.koushikdutta.async.AsyncServer;
import com.koushikdutta.async.AsyncServerSocket;
import com.koushikdutta.async.AsyncSocket;
import com.koushikdutta.async.ByteBufferList;
import com.koushikdutta.async.DataEmitter;
import com.koushikdutta.async.Util;
import com.koushikdutta.async.callback.CompletedCallback;
import com.koushikdutta.async.callback.DataCallback;
import com.koushikdutta.async.callback.ListenCallback;
import com.sportdream.DreamSDK.Delegate.LocalServerCoreDelegate;
import com.sportdream.DreamSDK.LocalServerCore;
import com.sportdream.network.LocalClientInfo;
import com.sportdream.network.PacketIDDef;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by lili on 2018/4/28.
 */

public class LocalServerModule extends ReactContextBaseJavaModule implements LocalServerCoreDelegate {
    protected ReactApplicationContext context;
    private LocalServerCore localServerCore;

    public LocalServerModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
        localServerCore = new LocalServerCore();
        localServerCore.addDelegate(this);
    }
    @Override
    public String getName(){
        return "LocalServerModule";
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    //delegate
    public void LocalServerListening(){

    }
    public void LocalServerRemoteClientAccepted(){

    }
    public void LocalServerRemoteClientLogined(LocalClientInfo info){
        WritableMap params = Arguments.createMap();
        params.putString("deviceID",info.deviceID);
        sendEvent("onRemoteClientLogined", params);
    }
    public void LocalServerRemoteClientClosed(LocalClientInfo info){
        WritableMap params = Arguments.createMap();
        params.putString("deviceID",info.deviceID);
        sendEvent("serverSocketDisconnect", params);
    }
    public void LocalServerClosed(){

    }
    public void LocalServerRemoteClientDataReceived(LocalClientInfo info,short PacketID,byte[] data){

        if(PacketID == PacketIDDef.JSON_MESSAGE){
            String json_str = new String(data);
            WritableMap params = Arguments.createMap();
            params.putString("deviceID",info.deviceID);
            params.putString("json_str",json_str);
            sendEvent("serverReceiveData", params);
        }

    }

    @ReactMethod
    public void startServer(String host,int udpport,int tcpport){
        localServerCore.startServer(host,tcpport);
    }

    @ReactMethod
    public void stopServer(){
        localServerCore.stopServer();
    }

    @ReactMethod
    public void serverSend(String message,String deviceID){
        localServerCore.send(deviceID,PacketIDDef.JSON_MESSAGE,message.getBytes());
    }
}
