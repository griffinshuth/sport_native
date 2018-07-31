package com.sportdream.DreamSDK;

import com.koushikdutta.async.AsyncServer;
import com.koushikdutta.async.AsyncSocket;
import com.koushikdutta.async.ByteBufferList;
import com.koushikdutta.async.DataEmitter;
import com.koushikdutta.async.Util;
import com.koushikdutta.async.callback.CompletedCallback;
import com.koushikdutta.async.callback.ConnectCallback;
import com.koushikdutta.async.callback.DataCallback;
import com.sportdream.DreamSDK.Delegate.LocalClientCoreDelegate;
import com.sportdream.network.BufferedPacketInfo;
import com.sportdream.network.LocalClientInfo;
import com.sportdream.network.SocketBuffer;

/**
 * Created by lili on 2018/5/2.
 */

public class LocalClientCore {
    private LocalClientInfo mSocketInfo;
    private LocalClientCoreDelegate mDelegate;

    public LocalClientCore(){
        mSocketInfo = new LocalClientInfo();
    }

    public void addDelegate(LocalClientCoreDelegate delegate){
        mDelegate = delegate;
    }

    private void handleConnectCompleted(Exception ex,final AsyncSocket socket){
        if(socket == null){
            mDelegate.LocalClientConnectFailed();
            return;
        }
        mSocketInfo.socket = socket;
        mDelegate.LocalClientConnected();
        socket.setDataCallback(new DataCallback() {
            @Override
            public void onDataAvailable(DataEmitter emitter, ByteBufferList bb) {
                byte[] t = bb.getAllByteArray();
                mSocketInfo.buffer.addData(t);
                BufferedPacketInfo packet = mSocketInfo.buffer.nextPacket(null);
                BufferedPacketInfo last = null;
                while(packet != null){
                    byte[] data = packet.data;
                    short id = packet.packetID;
                    mDelegate.LocalClientDataReceived(id,data);
                    last = packet;
                    packet = mSocketInfo.buffer.nextPacket(last);
                }
            }
        });

        socket.setClosedCallback(new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {
                mDelegate.LocalClientDisconnected();
            }
        });

        socket.setEndCallback(new CompletedCallback() {
            @Override
            public void onCompleted(Exception ex) {

            }
        });
    }

    public void connectServer(String host,int port){
        AsyncServer.getDefault().connectSocket(host, port, new ConnectCallback() {
            @Override
            public void onConnectCompleted(Exception ex, AsyncSocket socket) {
                handleConnectCompleted(ex,socket);
            }
        });
    }

    public void disconnect(){
        if(mSocketInfo.socket != null){
            mSocketInfo.socket.end();
        }
    }

    public void send(short PacketID,byte[] data){
        if(mSocketInfo.socket != null){
            byte[] packet = SocketBuffer.createPacket(PacketID,data);
            Util.writeAll(mSocketInfo.socket, packet, new CompletedCallback() {
                @Override
                public void onCompleted(Exception ex) {

                }
            });
        }
    }
}
