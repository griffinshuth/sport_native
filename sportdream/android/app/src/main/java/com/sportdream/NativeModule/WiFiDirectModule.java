package com.sportdream.NativeModule;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.NetworkInfo;
import android.net.wifi.p2p.WifiP2pConfig;
import android.net.wifi.p2p.WifiP2pDevice;
import android.net.wifi.p2p.WifiP2pDeviceList;
import android.net.wifi.p2p.WifiP2pInfo;
import android.net.wifi.p2p.WifiP2pManager;
import android.os.AsyncTask;
import android.os.Looper;
import android.provider.Settings;
import android.support.annotation.Nullable;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.koushikdutta.async.AsyncServer;
import com.koushikdutta.async.AsyncServerSocket;
import com.koushikdutta.async.AsyncSocket;
import com.koushikdutta.async.ByteBufferList;
import com.koushikdutta.async.DataEmitter;
import com.koushikdutta.async.Util;
import com.koushikdutta.async.callback.CompletedCallback;
import com.koushikdutta.async.callback.ConnectCallback;
import com.koushikdutta.async.callback.DataCallback;
import com.koushikdutta.async.callback.ListenCallback;
import com.sportdream.network.BufferedPacketInfo;
import com.sportdream.network.LocalClientInfo;
import com.sportdream.network.PacketIDDef;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collection;
import java.util.HashMap;

/**
 * Created by lili on 2017/10/18.
 */

public class WiFiDirectModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
    public WiFiDirectModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
        reactContext.addLifecycleEventListener(this);
        wifiP2pManager = (WifiP2pManager) reactContext.getSystemService(Context.WIFI_P2P_SERVICE);
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    protected ReactApplicationContext context;
    private WifiP2pInfo mWifiP2pInfo;
    private WifiP2pManager wifiP2pManager;
    private WifiP2pManager.Channel wifiDirectChannel;
    private int port = 7777;
    private AsyncServerSocket mServerSocket;
    private HashMap mRemoteSockets;
    private AsyncSocket mClientSocket;

    private WifiP2pManager.PeerListListener mPeerListListener = new WifiP2pManager.PeerListListener(){
        @Override
        public void onPeersAvailable(WifiP2pDeviceList peersList) {
            Collection<WifiP2pDevice> aList = peersList.getDeviceList();
            Object[] arr = aList.toArray();
            WritableMap params = Arguments.createMap();
            WritableArray array = Arguments.createArray();
            for (int i = 0; i < arr.length; i++) {
                WifiP2pDevice a = (WifiP2pDevice) arr[i];
                WritableMap singlemap = Arguments.createMap();
                singlemap.putString("Address",a.deviceAddress);
                singlemap.putString("name",a.deviceName);
                array.pushMap(singlemap);
            }
            params.putArray("peerlist",array);
            sendEvent("onWifiDirectPeers",params);
        }
    };
    private WifiP2pManager.ConnectionInfoListener mInfoListener = new WifiP2pManager.ConnectionInfoListener(){
        @Override
        public void onConnectionInfoAvailable(final WifiP2pInfo minfo) {
            if(minfo.isGroupOwner){
                //服务器
                mWifiP2pInfo = minfo;
                WritableMap params = Arguments.createMap();
                params.putString("type","GroupOwner");
                sendEvent("onWifiDirectPeerConnected",params);
                //启动服务器
                if(mServerSocket == null){
                    initServer();
                }

            }else if(minfo.groupFormed){
                //客户端
                mWifiP2pInfo = minfo;
                WritableMap params = Arguments.createMap();
                params.putString("type","groupFormed");
                sendEvent("onWifiDirectPeerConnected",params);
            }
        }
    };

    private BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION.equals(action)){
                wifiP2pManager.requestPeers(wifiDirectChannel,mPeerListListener);
            }else if(WifiP2pManager.WIFI_P2P_DISCOVERY_CHANGED_ACTION.equals(action)){

            }else if(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION.equals(action)){
                NetworkInfo networkInfo = (NetworkInfo)intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO);
                if(networkInfo.isConnected()){
                    Log.i("sportdream", "已连接");
                    wifiP2pManager.requestConnectionInfo(wifiDirectChannel,mInfoListener);
                }else{
                    Log.i("sportdream", "断开连接");
                    WritableMap params = Arguments.createMap();
                    sendEvent("onWifiDirectPeerDisconnected",params);
                    if(mServerSocket != null){
                        mServerSocket.stop();
                        mServerSocket = null;
                    }
                    if(mClientSocket != null){
                        mClientSocket.close();
                        mClientSocket = null;
                    }
                }
            }
        }
    };

    @Override
    public String getName(){
        return "WiFiDirectModule";
    }

    @Override
    public void onHostResume(){
        wifiDirectChannel = wifiP2pManager.initialize(context, Looper.myLooper(),null);
        IntentFilter mFilter = new IntentFilter();
        mFilter.addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION);
        mFilter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION);
        mFilter.addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION);
        mFilter.addAction(WifiP2pManager.WIFI_P2P_DISCOVERY_CHANGED_ACTION);
        mFilter.addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION);
        context.registerReceiver(broadcastReceiver, mFilter);
    }

    @Override
    public void onHostPause(){
        context.unregisterReceiver(broadcastReceiver);
        wifiP2pManager.removeGroup(wifiDirectChannel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
            }

            @Override
            public void onFailure(int reason) {

            }
        });
    }

    @Override
    public void onHostDestroy(){

    }

    @ReactMethod
    public void discoverPeers(){
        wifiP2pManager.discoverPeers(wifiDirectChannel,new WifiP2pManager.ActionListener(){
            @Override
            public void onSuccess() {
            }

            @Override
            public void onFailure(int reason) {
            }
        });
    }

    @ReactMethod
    public void wifiDirectConnect(String address){
        WifiP2pConfig config = new WifiP2pConfig();
        config.deviceAddress = address;
        wifiP2pManager.connect(wifiDirectChannel,config,new WifiP2pManager.ActionListener() {

            @Override
            public void onSuccess() {

            }

            @Override
            public void onFailure(int reason) {
                WritableMap params = Arguments.createMap();
                sendEvent("onWifiDirectPeerConnectFailed",params);
            }
        });
    }

    @ReactMethod
    public void wifiDirectDisconnect(){
        wifiP2pManager.removeGroup(wifiDirectChannel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {

            }

            @Override
            public void onFailure(int reason) {

            }
        });
    }

    private void handleConnectCompleted(Exception ex,final AsyncSocket socket){
        if(socket == null){
            WritableMap params = Arguments.createMap();
            sendEvent("onWifiDirectClientConnectError",params);
            return;
        }
        WritableMap params = Arguments.createMap();
        sendEvent("onWifiDirectClientConnected",params);
        mClientSocket = socket;
        socket.setDataCallback(new DataCallback() {
            @Override
            public void onDataAvailable(DataEmitter emitter, ByteBufferList bb) {
                byte[] t = bb.getAllByteArray();
                String str = new String(t);
                WritableMap params = Arguments.createMap();
                params.putString("data",str);
                sendEvent("onWifiDirectClientDataReceived",params);

            }
        });

        socket.setClosedCallback(new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {

            }
        });

        socket.setEndCallback(new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {
                WritableMap params = Arguments.createMap();
                sendEvent("onWifiDirectClientDisconnected",params);
            }
        });
    }

    @ReactMethod
    public void connectServer(){
        String host = mWifiP2pInfo.groupOwnerAddress.getHostAddress();
        AsyncServer.getDefault().connectSocket(host, port, new ConnectCallback() {
            @Override
            public void onConnectCompleted(Exception ex, AsyncSocket socket) {
                handleConnectCompleted(ex,socket);
            }
        });
    }

    private void handleAccept(final AsyncSocket socket){
        WritableMap params = Arguments.createMap();
        sendEvent("onWifiDirectRemoteSocketConnected",params);
        socket.setDataCallback(new DataCallback() {
            @Override
            public void onDataAvailable(DataEmitter emitter, ByteBufferList bb) {
                byte[] t = bb.getAllByteArray();
                String str = new String(t);
                WritableMap params = Arguments.createMap();
                params.putString("data",str);
                sendEvent("onWifiDirectServerDataReceived",params);
                //echo
                Util.writeAll(socket, "world".getBytes(), new CompletedCallback() {
                    @Override
                    public void onCompleted(Exception ex) {

                    }
                });
            }
        });

        socket.setClosedCallback(new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {

            }
        });

        socket.setEndCallback(new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {
                WritableMap params = Arguments.createMap();
                sendEvent("onWifiDirectRemoteSocketDisconnected",params);
            }
        });
    }

    @ReactMethod
    public void initServer(){
        mServerSocket = AsyncServer.getDefault().listen(null, port, new ListenCallback() {
            @Override
            public void onAccepted(AsyncSocket socket) {
                handleAccept(socket);
            }

            @Override
            public void onListening(AsyncServerSocket socket) {
                WritableMap params = Arguments.createMap();
                sendEvent("onWifiDirectServerRuning",params);
            }

            @Override
            public void onCompleted(Exception ex) {

            }
        });
    }

    @ReactMethod
    public void clientSendData(String data){
        if(mClientSocket == null){
            return;
        }
        Util.writeAll(mClientSocket, data.getBytes(), new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {

            }
        });
    }

    @ReactMethod
    public void serverSendData(String data){

    }
}
