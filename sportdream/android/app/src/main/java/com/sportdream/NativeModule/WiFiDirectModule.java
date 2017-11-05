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
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collection;

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
    private WifiP2pManager.PeerListListener mPeerListListener = new WifiP2pManager.PeerListListener(){
        @Override
        public void onPeersAvailable(WifiP2pDeviceList peersList) {
            Collection<WifiP2pDevice> aList = peersList.getDeviceList();
            Object[] arr = aList.toArray();
            for (int i = 0; i < arr.length; i++) {
                WifiP2pDevice a = (WifiP2pDevice) arr[i];
                WritableMap params = Arguments.createMap();
                params.putString("Address",a.deviceAddress);
                params.putString("name",a.deviceName);
                sendEvent("onWifiDirectPeers",params);
            }
        }
    };
    private WifiP2pManager.ConnectionInfoListener mInfoListener = new WifiP2pManager.ConnectionInfoListener(){
        @Override
        public void onConnectionInfoAvailable(final WifiP2pInfo minfo) {
            if(minfo.isGroupOwner){
                //服务器
                mWifiP2pInfo = minfo;
                WritableMap params = Arguments.createMap();
                params.putString("type","server");
                sendEvent("onWifiDirectConnected",params);
                AsyncTask<Void, Void, String> mDataServerTask = new AsyncTask<Void, Void, String>() {
                    @Override
                    protected String doInBackground(Void... params) {
                        try {
                            ServerSocket serverSocket = new ServerSocket(8888);
                            Socket client = serverSocket.accept();
                            InputStream inputStream = client.getInputStream();
                            ByteArrayOutputStream baos = new ByteArrayOutputStream();
                            int i;
                            while ((i = inputStream.read()) != -1){
                                baos.write(i);
                            }
                            String str = baos.toString();
                            serverSocket.close();
                            return str;
                        }catch (IOException e){
                            return null;
                        }
                    }
                    @Override
                    protected void onPostExecute(String result){
                        Toast.makeText(context,"result:"+result, Toast.LENGTH_SHORT).show();
                        wifiP2pManager.removeGroup(wifiDirectChannel, new WifiP2pManager.ActionListener() {
                            @Override
                            public void onSuccess() {
                            }

                            @Override
                            public void onFailure(int reason) {

                            }
                        });
                    }
                };
                mDataServerTask.execute();
            }else if(minfo.groupFormed){
                //客户端
                mWifiP2pInfo = minfo;
                WritableMap params = Arguments.createMap();
                params.putString("type","client");
                sendEvent("onWifiDirectConnected",params);
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
    public void initWifiDirect(){
        Activity currentActivity = getCurrentActivity();
        /*wifiP2pManager = (WifiP2pManager)currentActivity.getSystemService(Context.WIFI_P2P_SERVICE);
        wifiDirectChannel = wifiP2pManager.initialize(context, context.getMainLooper(), new WifiP2pManager.ChannelListener() {
            @Override
            public void onChannelDisconnected() {

            }
        });*/
        Intent intent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
        currentActivity.startActivity(intent);
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


            }
        });
    }

    @ReactMethod
    public void wifiDirectSendData(String data){
        Socket socket = new Socket();
        String host = mWifiP2pInfo.groupOwnerAddress.getHostAddress();
        int port = 8888;
        try{
            socket.connect(new InetSocketAddress(host,port),5000);
            OutputStream stream = socket.getOutputStream();

            stream.write(data.getBytes());
        }catch (IOException e){

        }finally {
            if(socket != null){
                if (socket.isConnected()) {
                    try {
                        socket.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }
}
