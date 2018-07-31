package com.sportdream.network;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.widget.Toast;

import java.io.IOException;
import java.io.InputStream;
import java.io.InterruptedIOException;
import java.io.OutputStream;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.UnknownHostException;

/**
 * Created by lili on 2018/1/22.
 */

public class LocalWifiNetworkThread extends Thread {

    private static final int ACTION_THREAD_QUIT = 0X1010;
    private static final int ACTION_SEND_DATA = 0X2010;
    private static final class LocalWifiNetworkThreadHandler extends Handler{
        private LocalWifiNetworkThread mThread;
        public LocalWifiNetworkThreadHandler(LocalWifiNetworkThread thread){
            mThread = thread;
        }
        public void release(){
            mThread = null;
        }

        @Override
        public void handleMessage(Message msg){
            if(mThread == null){
                return;
            }

            switch (msg.what){
                case ACTION_THREAD_QUIT:
                    mThread.exit();
                    break;
                case ACTION_SEND_DATA:
                    Object[] params = (Object[]) msg.obj;
                    mThread.sendData((short)params[0],(byte[])params[1]);
                    break;
            }
        }
    }

    private LocalWifiNetworkThreadHandler mHandler;
    private DatagramSocket mBroadcastUDP;
    private ServerSocket tempSocket = null;
    private Socket clientSocket = null;
    private Thread tempSocketThread = null;
    private Thread clientSocketThread = null;
    private String directorServerIP = "";
    private SocketBuffer socketBuffer = new SocketBuffer();
    private LocalWifiSocketHandler mListener;

    private int TEMP_TCP_PORT = 3333;
    private int DIRECTOR_SERVER_PORT = 6666;
    private int UDP_BROADCAST_PORT = 8888;

    public LocalWifiNetworkThread(LocalWifiSocketHandler listener){
        mListener = listener;
        initSocket();
    }

    private void initSocket(){
        try{
            mBroadcastUDP = new DatagramSocket();
            mBroadcastUDP.setBroadcast(true);
        }catch (IOException e){
            e.printStackTrace();
        }

            tempSocketThread = new Thread(){
                @Override
                public void run() {
                    try{
                        tempSocket = new ServerSocket(TEMP_TCP_PORT);
                        while (!this.isInterrupted()){
                            Socket socket = tempSocket.accept();
                            directorServerIP = socket.getInetAddress().getHostAddress();
                            clientSocketThread.start();
                            socket.close();
                        }
                    }catch (IOException e){
                        e.printStackTrace();
                    }
                    Log.w("sportstream","tempSocketThread closed");
                }
            };
            clientSocketThread = new Thread(){
                @Override
                public void run() {
                    try{
                        clientSocket = new Socket(directorServerIP,DIRECTOR_SERVER_PORT);
                        mListener.DirectServerConnected();
                    }catch (IOException e){
                        e.printStackTrace();
                    }
                    byte[] buffer = new byte[1024*1024];
                    try{
                        InputStream in = clientSocket.getInputStream();
                        while (!this.isInterrupted()){
                            int len = in.read(buffer);
                            if(len == -1){
                                Log.w("sportstream","in.read(buffer);");
                                mListener.DirectServerDisconnected();
                                break;
                            }
                            byte[] oneread = new byte[len];
                            System.arraycopy(buffer,0,oneread,0,len);
                            socketBuffer.addData(oneread);
                            BufferedPacketInfo packet = socketBuffer.nextPacket(null);
                            BufferedPacketInfo last = null;
                            while(packet != null){

                                byte[] data = packet.data;
                                short id = packet.packetID;
                                mListener.DataReceived(id,data);
                                last = packet;
                                packet = socketBuffer.nextPacket(last);
                            }
                        }
                        in.close();
                    }catch (IOException e){
                        e.printStackTrace();
                        Log.w("sportstream","clientSocket closed");
                    }
                    Log.w("sportstream","clientSocketThread closed");
                }
            };
            tempSocketThread.start();
    }

    @Override
    public void run(){
        Looper.prepare();
        mHandler = new LocalWifiNetworkThreadHandler(this);
        Looper.loop();
    }

    private void udpBroadcast(final String ip,final int port,final String info){
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

    public void searchServer(){
        udpBroadcast("255.255.255.255",UDP_BROADCAST_PORT,"androidbroadcast");
    }

    public final void exit(){
        if(Thread.currentThread() != this){
            mHandler.sendEmptyMessage(ACTION_THREAD_QUIT);
            return;
        }
        //本线程的处理
        try {
            tempSocket.close();
            if(clientSocket != null){
                clientSocket.close();
            }
        }catch (IOException e){
            e.printStackTrace();
        }
        tempSocketThread.interrupt();
        clientSocketThread.interrupt();
        Looper.myLooper().quit();
        mHandler.release();
    }

    public final void sendData(short PacketID,byte[] data){
        if(Thread.currentThread() != this){
            Message envelop = new Message();
            envelop.what = ACTION_SEND_DATA;
            envelop.obj = new Object[]{PacketID, data};
            mHandler.sendMessage(envelop);
            return;
        }

        byte[] packet = SocketBuffer.createPacket(PacketID,data);
        try{
            OutputStream os = clientSocket.getOutputStream();
            os.write(packet);
        }catch(IOException e){
            e.printStackTrace();
        }
    }

}






















































