package com.sportdream.NativeModule;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.net.wifi.p2p.WifiP2pManager;
import android.os.Build;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.IOException;
import java.io.InputStream;
import java.io.InterruptedIOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Set;
import java.util.UUID;

import android.os.Looper;
import android.provider.Settings;
import android.support.annotation.Nullable;
import android.util.Log;

/**
 * Created by lili on 2017/10/16.
 */

public class ClassicBlueToothModule extends ReactContextBaseJavaModule {

    protected ReactApplicationContext context;
    private BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
    private UUID uuid = UUID.fromString("a60f35f0-b93a-11de-8a39-08002009c666");
    private static final int BLUETOOCH_OPEN_REQUEST = 467081;
    private static final int BLUETOOCH_DISCOVERABLE_REQUEST = 467082;
    private static final int CHOOSE_FILE_REQUEST = 467083;
    private Promise mOpenBluetoothPromise;
    private Promise mDiscoverableBluetoothPromise;
    private Promise mChooseFilePromise;
    private BluetoothSocket mListeningBTSocket;
    private boolean mIsListening = false;
    private BluetoothSocket mRemoteBTSocket;
    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener(){
        @Override
        public void onActivityResult(Activity activity,int requestCode,int resultCode,Intent intent){
            if(requestCode == BLUETOOCH_OPEN_REQUEST){
                if (mOpenBluetoothPromise != null) {
                    if(resultCode == Activity.RESULT_OK){
                        mOpenBluetoothPromise.resolve("success");
                    }else{
                        mOpenBluetoothPromise.resolve("Canceled");
                    }
                    mOpenBluetoothPromise = null;
                }
            }else if(requestCode == BLUETOOCH_DISCOVERABLE_REQUEST){
                if(mDiscoverableBluetoothPromise != null){
                    if(resultCode != Activity.RESULT_CANCELED){
                        mDiscoverableBluetoothPromise.resolve("success");
                    }else{
                        mDiscoverableBluetoothPromise.resolve("canceled");
                    }
                    mDiscoverableBluetoothPromise = null;
                }
            }else if(requestCode == CHOOSE_FILE_REQUEST){
                if(resultCode == Activity.RESULT_OK){
                    Uri uri = intent.getData();//得到uri，后面就是将uri转化成file的过程。
                    String string =uri.toString();
                    mChooseFilePromise.resolve(string);
                }else{
                    mChooseFilePromise.resolve("canceled");
                }
                mChooseFilePromise = null;
            }
        }
    };

    private ArrayList<BluetoothDevice> devicelist = new ArrayList<BluetoothDevice>();

    private BroadcastReceiver discoveryMonitor = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if(BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(intent.getAction())){
                Log.i("sportdream","Discovery started...");
                sendEvent("onBluetoothDiscoverStarted",null);
            }else if(BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(intent.getAction())){
                Log.i("sportdream","Discovery end");
                sendEvent("onBluetoothDiscoverEnded",null);
            }
        }
    };

    private BroadcastReceiver discoveryResult = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String name = intent.getStringExtra(BluetoothDevice.EXTRA_NAME);
            BluetoothDevice remotedevice = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
            devicelist.add(remotedevice);
            WritableMap params = Arguments.createMap();
            params.putString("DeviceName",name);
            params.putString("Address",remotedevice.getAddress());
            //判断该设备是否已经配对
            BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
            Set<BluetoothDevice> bondedDevices = bluetooth.getBondedDevices();
            if(bondedDevices.contains(remotedevice)){
                params.putBoolean("bonded",true);
            }else{
                params.putBoolean("bonded",false);
            }
            sendEvent("onBluetoothFounded",params);
        }
    };

    public ClassicBlueToothModule(ReactApplicationContext reactContext)
    {
        super(reactContext);
        context = reactContext;
        reactContext.addActivityEventListener(mActivityEventListener);
        //启动蓝牙监听
        BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
        String name = "bluetoothserver";
        try{
            final BluetoothServerSocket btserver = bluetooth.listenUsingRfcommWithServiceRecord(name,uuid);
            Thread acceptThread = new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        mListeningBTSocket = btserver.accept();
                        BluetoothDevice device = mListeningBTSocket.getRemoteDevice();
                        WritableMap map = Arguments.createMap();
                        map.putString("name",device.getName());
                        sendEvent("onConnectAccepted",map);
                    }catch (IOException e){

                    }
                }
            });
            acceptThread.start();
        }catch (IOException e){

        }

        //接受远端发送过来的数据
        Thread listenDataThread = new Thread(new Runnable() {
            @Override
            public void run() {
                int bufferSize = 1024;
                byte[] buffer = new byte[bufferSize];
                try{
                    int bytesRead = -1;
                    while(true){
                        if(mListeningBTSocket != null){
                            if(mListeningBTSocket.isConnected()){
                                InputStream instream = mListeningBTSocket.getInputStream();
                                bytesRead = instream.read(buffer);
                                if(bytesRead != -1){
                                    String result = new String(buffer,0,bytesRead-1);
                                    WritableMap map = Arguments.createMap();
                                    map.putString("data",result);
                                    map.putString("Address",mListeningBTSocket.getRemoteDevice().getAddress());
                                    sendEvent("onDataReceived",map);
                                }
                            }
                        }
                        try {
                            Thread.sleep(100);
                        }catch (InterruptedException e){

                        }
                    }
                }catch (IOException e){

                }
            }
        });
        listenDataThread.start();

        //接受远端发送过来的数据
        Thread remoteDataThread = new Thread(new Runnable() {
            @Override
            public void run() {
                int bufferSize = 1024;
                byte[] buffer = new byte[bufferSize];
                try{
                    int bytesRead = -1;
                    while(true){
                        if(mRemoteBTSocket != null){
                            if(mRemoteBTSocket.isConnected()){
                                InputStream instream = mRemoteBTSocket.getInputStream();
                                bytesRead = instream.read(buffer);
                                if(bytesRead != -1){
                                    String result = new String(buffer,0,bytesRead-1);
                                    WritableMap map = Arguments.createMap();
                                    map.putString("data",result);
                                    map.putString("Address",mRemoteBTSocket.getRemoteDevice().getAddress());
                                    sendEvent("onDataReceived",map);
                                }
                            }
                        }
                        try {
                            Thread.sleep(100);
                        }catch (InterruptedException e){

                        }
                    }
                }catch (IOException e){

                }
            }
        });
        remoteDataThread.start();
    }

    @Override
    public String getName()
    {
        return "ClassicBlueToothModule";
    }

    //获得蓝牙基本信息
    @ReactMethod
    public void getBlueToothInfo(Promise promise){
        BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
        WritableMap map = Arguments.createMap();
        if(bluetooth.isEnabled()){
            map.putBoolean("open",true);
            map.putString("mac",bluetooth.getAddress());
            map.putString("name",bluetooth.getName());
            if(bluetooth.getScanMode() == bluetooth.SCAN_MODE_NONE){
                map.putString("scanMode","可发现性被关闭");
            }else if(bluetooth.getScanMode() == bluetooth.SCAN_MODE_CONNECTABLE){
                map.putString("scanMode","绑定设备可发现");
            }else if(bluetooth.getScanMode() == bluetooth.SCAN_MODE_CONNECTABLE_DISCOVERABLE){
                map.putString("scanMode","所有设备可发现");
            }
        }else{
            //蓝牙设备没有打开
            map.putBoolean("open",false);
        }
        promise.resolve(map);
    }

    //打开蓝牙
    @ReactMethod
    public void openBluetooth(final Promise promise){
        BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
        if(!bluetooth.isEnabled()){
            mOpenBluetoothPromise = promise;
            Activity currentActivity = getCurrentActivity();
            currentActivity.startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE),BLUETOOCH_OPEN_REQUEST);
        }else{
            promise.resolve("alreadyOpen");
        }
    }

    //打开蓝牙可发现性
    @ReactMethod
    public void openDiscoverable(final Promise promise){
        BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
        if(bluetooth.getScanMode() != bluetooth.SCAN_MODE_CONNECTABLE_DISCOVERABLE){
            mDiscoverableBluetoothPromise = promise;
            Activity currentActivity = getCurrentActivity();
            currentActivity.startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE),BLUETOOCH_DISCOVERABLE_REQUEST);
        }else{
            promise.resolve("already discoverable");
        }
    }

    //蓝牙搜索
    @ReactMethod
    public void searchNearby(){
        Activity currentActivity = getCurrentActivity();
        BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
        currentActivity.registerReceiver(discoveryResult,new IntentFilter(BluetoothDevice.ACTION_FOUND));
        currentActivity.registerReceiver(discoveryMonitor,new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_STARTED));
        currentActivity.registerReceiver(discoveryMonitor,new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED));

        if(bluetooth.isEnabled() && !bluetooth.isDiscovering()){
            devicelist.clear();
            bluetooth.startDiscovery();
            //发送连接中的设备
            if(mListeningBTSocket!=null && mListeningBTSocket.isConnected()){
                BluetoothDevice device = mListeningBTSocket.getRemoteDevice();
                WritableMap params = Arguments.createMap();
                params.putString("DeviceName",device.getName());
                params.putString("Address",device.getAddress());
                params.putBoolean("connected",true);
                sendEvent("onBluetoothFounded",params);
            }
            if(mRemoteBTSocket != null && mRemoteBTSocket.isConnected()){
                BluetoothDevice device = mRemoteBTSocket.getRemoteDevice();
                WritableMap params = Arguments.createMap();
                params.putString("DeviceName",device.getName());
                params.putString("Address",device.getAddress());
                params.putBoolean("connected",true);
                sendEvent("onBluetoothFounded",params);
            }

        }
    }

    @ReactMethod
    public void chooseFile(final Promise promise){
        mChooseFilePromise = promise;
        Intent intent = new Intent();
        if (Build.VERSION.SDK_INT < 19) {
            intent.setAction(Intent.ACTION_GET_CONTENT);
            intent.setType("*/*");
        } else {
            intent.setAction(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("*/*");
        }
        Activity currentActivity = getCurrentActivity();
        currentActivity.startActivityForResult(intent,CHOOSE_FILE_REQUEST);
    }

    @ReactMethod
    public void BTConnect(String address,Promise promise){
        BluetoothDevice device = bluetooth.getRemoteDevice(address);
        //device.getUuids();
        try {
            mRemoteBTSocket = device.createRfcommSocketToServiceRecord(uuid);
            mRemoteBTSocket.connect();
            if(mRemoteBTSocket.isConnected()){
                promise.resolve("connect success");
            }else{
                promise.resolve("connect failed");
            }

        }catch (IOException e){

        }
    }

    @ReactMethod
    public void BTDisconnect(String address,Promise promise){
        if(mListeningBTSocket != null && mListeningBTSocket.getRemoteDevice().getAddress().equals(address)){
            try {
                if(mListeningBTSocket.isConnected()){
                    mListeningBTSocket.close();
                    mListeningBTSocket = null;
                    promise.resolve("success");
                }else{
                    promise.resolve("already closed");
                }
                return;
            }catch (IOException e){

            }
        }else if(mRemoteBTSocket != null && mRemoteBTSocket.getRemoteDevice().getAddress().equals(address)){
            try{
                if(mRemoteBTSocket.isConnected()){
                    mRemoteBTSocket.close();
                    mRemoteBTSocket = null;
                    promise.resolve("success");
                }else{
                    promise.resolve("already closed");
                }
                return;

            }catch (IOException e){

            }
        }
        promise.resolve("not exist");
    }

    @ReactMethod
    public void sendBTData(String address,String message,Promise promise){
        if(mListeningBTSocket != null && mListeningBTSocket.getRemoteDevice().getAddress().equals(address)){
            try{
                if(mListeningBTSocket.isConnected()){
                    OutputStream outStream = mListeningBTSocket.getOutputStream();
                    byte[] byteArray = (message+" ").getBytes();
                    byteArray[byteArray.length-1] = 0;
                    outStream.write(byteArray);
                    promise.resolve("success");
                }else{
                    promise.resolve("socket disconnected");
                }
                return;
            }catch (IOException e){

            }
        }else if(mRemoteBTSocket != null && mRemoteBTSocket.getRemoteDevice().getAddress().equals(address)){
            try{
                if(mRemoteBTSocket.isConnected()){
                    OutputStream outStream = mRemoteBTSocket.getOutputStream();
                    byte[] byteArray = (message+" ").getBytes();
                    byteArray[byteArray.length-1] = 0;
                    outStream.write(byteArray);
                    promise.resolve("success");
                }else{
                    promise.resolve("socket disconnected");
                }
                return;
            }catch (IOException e){

            }
        }
        promise.resolve("address not exist");
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }
}
