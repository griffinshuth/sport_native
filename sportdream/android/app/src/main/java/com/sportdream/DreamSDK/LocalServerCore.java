package com.sportdream.DreamSDK;

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
import com.sportdream.network.BufferedPacketInfo;
import com.sportdream.network.LocalClientInfo;
import com.sportdream.network.PacketIDDef;
import com.sportdream.network.SocketBuffer;

import org.json.JSONException;
import org.json.JSONObject;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;

/**
 * Created by lili on 2018/5/2.
 */

public class LocalServerCore {
    private ArrayList<LocalClientInfo> mRemoteSocketList;
    private AsyncServerSocket mServerSocket;
    private InetAddress mHost;
    private LocalServerCoreDelegate mDelegate;

    public LocalServerCore(){

    }

    public void addDelegate(LocalServerCoreDelegate delegate){
        mDelegate = delegate;
    }

    private void handleAccept(final AsyncSocket socket){
        LocalClientInfo localClientInfo = new LocalClientInfo();
        localClientInfo.socket = socket;
        mRemoteSocketList.add(localClientInfo);
        mDelegate.LocalServerRemoteClientAccepted();

        socket.setDataCallback(new DataCallback() {
            @Override
            public void onDataAvailable(DataEmitter emitter, ByteBufferList bb) {
                for(int i=0;i<mRemoteSocketList.size();i++){
                    if(socket == mRemoteSocketList.get(i).socket){
                        LocalClientInfo info = mRemoteSocketList.get(i);
                        byte[] t = bb.getAllByteArray();
                        info.buffer.addData(t);
                        BufferedPacketInfo packet = info.buffer.nextPacket(null);
                        BufferedPacketInfo last = null;
                        while(packet != null){
                            byte[] data = packet.data;
                            short id = packet.packetID;
                            if(id == PacketIDDef.JSON_MESSAGE){
                                String json_str = new String(data);
                                try {
                                    JSONObject jObject  = new JSONObject(json_str);
                                    String json_id = jObject.getString("id");
                                    if(json_id.equals("login")){
                                        String json_deviceID = jObject.getString("deviceID");
                                        info.deviceID = json_deviceID;

                                        mDelegate.LocalServerRemoteClientLogined(info);
                                    }
                                }catch (JSONException e){
                                    e.printStackTrace();
                                }
                            }
                            mDelegate.LocalServerRemoteClientDataReceived(info,id,data);
                            last = packet;
                            packet = info.buffer.nextPacket(last);
                        }
                    }
                }
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
                for(int i=0;i<mRemoteSocketList.size();i++){
                    if(socket == mRemoteSocketList.get(i).socket){
                        LocalClientInfo info = mRemoteSocketList.get(i);
                        mDelegate.LocalServerRemoteClientClosed(info);
                        mRemoteSocketList.remove(i);
                        break;
                    }
                }
            }
        });
    }

    public void startServer(String host,int port){
        mRemoteSocketList = new ArrayList();
        try {
            mHost = InetAddress.getByName(host);
        } catch (UnknownHostException e) {
            throw new RuntimeException(e);
        }

        mServerSocket = AsyncServer.getDefault().listen(mHost, port, new ListenCallback() {
            @Override
            public void onAccepted(AsyncSocket socket) {
                handleAccept(socket);
            }

            @Override
            public void onListening(AsyncServerSocket socket) {
                mDelegate.LocalServerListening();
            }

            @Override
            public void onCompleted(Exception ex) {
                mDelegate.LocalServerClosed();
            }
        });
    }

    public void stopServer(){
        mServerSocket.stop();
        for(int i=0;i<mRemoteSocketList.size();i++){
            mRemoteSocketList.get(i).socket.close();
        }
        mRemoteSocketList = null;
        mServerSocket = null;
    }

    public void send(String deviceID,short PacketID,byte[] data){
        for(int i=0;i<mRemoteSocketList.size();i++){
            if(mRemoteSocketList.get(i).deviceID.equals(deviceID)){
                byte[] packet = SocketBuffer.createPacket(PacketID,data);
                Util.writeAll(mRemoteSocketList.get(i).socket, packet, new CompletedCallback() {
                    @Override
                    public void onCompleted(Exception ex) {

                    }
                });
                break;
            }
        }
    }
}
