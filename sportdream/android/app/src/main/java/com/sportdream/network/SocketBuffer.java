package com.sportdream.network;

import java.net.Socket;
import java.nio.ByteBuffer;

/**
 * Created by lili on 2017/12/28.
 */

public class SocketBuffer {
    public Socket socket;
    private int maxSize;
    public byte[] buffer;
    public int currentSize;


    public SocketBuffer(){
        socket = null;
        maxSize = 1024*1024;
        buffer = new byte[maxSize];
        currentSize = 0;
    }

    public boolean addData(byte[] data){
        int length = data.length;
        int availSize = maxSize - currentSize;
        if(availSize<length){
            return false;
        }
        System.arraycopy(data,0,buffer,currentSize,length);
        currentSize = currentSize+length;
        return true;
    }

    public BufferedPacketInfo nextPacket(BufferedPacketInfo last){
        if(last != null){
            int t = currentSize-(last.data.length+6);
            System.arraycopy(buffer,last.data.length+6,buffer,0,t);
            currentSize = t;
        }
        if(currentSize<6){
            return null;
        }

        ByteBuffer int_buffer = ByteBuffer.wrap(buffer,0,4);
        int len = int_buffer.getInt();
        ByteBuffer short_buffer = ByteBuffer.wrap(buffer,4,2);
        short packetID = short_buffer.getShort();
        if((currentSize-6)<len){
            return null;
        }
        byte[] data = new byte[len];
        System.arraycopy(buffer,6,data,0,len);
        BufferedPacketInfo packet = new BufferedPacketInfo();
        packet.packetID = packetID;
        packet.data = data;
        return packet;
    }

    static public byte[] createPacket(short ID,byte[] data){
        int length = data.length;
        byte[] packet = new byte[length+6];
        ByteBuffer packet_buffer = ByteBuffer.allocate(length+6);
        packet_buffer.putInt(length);
        packet_buffer.putShort(ID);
        packet_buffer.put(data);
        packet_buffer.flip();
        packet_buffer.get(packet,0,length+6);
        return packet;
    }

}
