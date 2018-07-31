package com.sportdream.NativeModule;

import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.koushikdutta.async.AsyncServer;
import com.koushikdutta.async.AsyncSocket;
import com.koushikdutta.async.ByteBufferList;
import com.koushikdutta.async.DataEmitter;
import com.koushikdutta.async.Util;
import com.koushikdutta.async.callback.CompletedCallback;
import com.koushikdutta.async.callback.ConnectCallback;
import com.koushikdutta.async.callback.DataCallback;
import com.sportdream.DreamSDK.Delegate.LocalClientCoreDelegate;
import com.sportdream.DreamSDK.LocalClientCore;
import com.sportdream.network.H264FrameMetaData;
import com.sportdream.network.PacketIDDef;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InterruptedIOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;

/**
 * Created by lili on 2018/4/28.
 */

public class LocalClientModule extends ReactContextBaseJavaModule implements LocalClientCoreDelegate {
    private LocalClientCore localClientCore;
    protected ReactApplicationContext context;
    private int TEMP_TCP_PORT = 3333;
    private int DIRECTOR_SERVER_PORT = 6666;
    private int UDP_BROADCAST_PORT = 8888;
    private DatagramSocket mBroadcastUDP;
    private ServerSocket tempSocket = null;
    private Thread tempSocketThread = null;
    private String directorServerIP = "";

    public LocalClientModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
        localClientCore = new LocalClientCore();
        localClientCore.addDelegate(this);
    }
    @Override
    public String getName(){
        return "LocalClientModule";
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    //delegate begin
    public void LocalClientConnectFailed(){
        WritableMap params = Arguments.createMap();
        sendEvent("clientConnectFailed", params);
    }
    public void LocalClientConnected(){
        WritableMap params = Arguments.createMap();
        sendEvent("clientSocketConnected", params);
    }
    public void LocalClientDisconnected(){
        WritableMap params = Arguments.createMap();
        sendEvent("clientSocketDisconnect", params);
    }
    public void LocalClientDataReceived(short PacketID,byte[] data){
        if(PacketID == PacketIDDef.JSON_MESSAGE){
            String json_str = new String(data);
            WritableMap params = Arguments.createMap();
            params.putString("data",json_str);
            sendEvent("clientReceiveData", params);
        }
    }
    //degegate end


    private void udpSend(final String ip,final int port,final String info){
        new Thread(){
            public void run(){
                try{
                    InetAddress addr = InetAddress.getByName(ip);
                    byte[] buffer = info.getBytes();
                    DatagramPacket packet = new DatagramPacket(buffer,buffer.length);
                    packet.setAddress(addr);
                    packet.setPort(port);
                    mBroadcastUDP.send(packet);
                }catch (SocketException e){
                    e.printStackTrace();
                }catch (UnknownHostException e){
                    e.printStackTrace();
                }catch (IOException e){
                    e.printStackTrace();
                }
            }
        }.start();
    }

    private void udpBroadcast(){
        udpSend("255.255.255.255",UDP_BROADCAST_PORT,"androidbroadcast");
    }



    @ReactMethod
    public void startClient(int udpport,int tcpport){
        UDP_BROADCAST_PORT = udpport;
        DIRECTOR_SERVER_PORT = tcpport;
    }

    @ReactMethod
    public void connectServer(String host){
        localClientCore.connectServer(host,DIRECTOR_SERVER_PORT);
    }

    @ReactMethod
    public void stopClient(){
        localClientCore.disconnect();
    }

    @ReactMethod
    public void searchServer(){
        if(tempSocketThread != null && tempSocketThread.isAlive()){
            return;
        }
        directorServerIP = "";
        try {
            mBroadcastUDP = new DatagramSocket();
            mBroadcastUDP.setBroadcast(true);
            tempSocketThread = new Thread(){
                @Override
                public void run() {
                    try{
                        tempSocket = new ServerSocket(TEMP_TCP_PORT);
                        tempSocket.setSoTimeout(3000);
                        Socket director_socket = tempSocket.accept();
                        directorServerIP = director_socket.getInetAddress().getHostAddress();
                        WritableMap params = Arguments.createMap();
                        sendEvent("serverDiscovered", params);
                        localClientCore.connectServer(directorServerIP,DIRECTOR_SERVER_PORT);
                        director_socket.close();
                        tempSocket.close();
                        tempSocket = null;
                    }catch (SocketTimeoutException e){
                        e.printStackTrace();
                        try{
                            tempSocket.close();
                            tempSocket = null;
                        }catch (IOException e2){
                            e2.printStackTrace();
                        }
                        WritableMap params = Arguments.createMap();
                        sendEvent("onSearchServerTimeout", params);
                    }catch (IOException e){
                        e.printStackTrace();
                    }

                }
            };
            tempSocketThread.start();
            udpBroadcast();
        }catch (IOException e){
            e.printStackTrace();
        }
    }

    @ReactMethod
    public void commonLogin(String deviceID){
        String json = "{\"id\":\"login\",\"deviceID\":\"%s\"}";
        String json_str = String.format(json,deviceID);
        clientSend(json_str);
    }

    @ReactMethod
    public void clientSend(String message){
        localClientCore.send(PacketIDDef.JSON_MESSAGE,message.getBytes());
    }
}
