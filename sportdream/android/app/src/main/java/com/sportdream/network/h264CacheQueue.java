package com.sportdream.network;

import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedList;
import java.util.Queue;

/**
 * Created by lili on 2018/1/22.
 */

public class h264CacheQueue implements LocalWifiSocketHandler {

    private static final short START_SEND_BIGDATA = 1;
    private static final short STOP_SEND_BIGDATA = 2;
    private static final short START_SEND_SMALLDATA = 3;
    private static final short STOP_SEND_SMALLDATA = 4;
    private static final short SEND_BIG_H264DATA = 5;
    private static final short SEND_SMALL_H264SDATA = 6;
    private static final short CAMERA_NAME = 7;

    private final class h264Frame{
        public boolean isKeyFrame;
        public byte[] frameData;
        public double timestamp;
    }
    private final class SpsPpsMetaData{
        public byte[] sps;
        public byte[] pps;
    }

    private SpsPpsMetaData bigMetaData = new SpsPpsMetaData();
    private LinkedList<h264Frame> bigH264Queue = new LinkedList<h264Frame>();
    private LinkedList<h264Frame> bigKeyFrameList = new LinkedList<h264Frame>();
    private h264Frame lastBigKeyFrame = null;
    private h264Frame lastSendBigFrame = null;

    private SpsPpsMetaData smallMetaData = new SpsPpsMetaData();
    private LinkedList<h264Frame> smallH264Queue = new LinkedList<h264Frame>();
    private LinkedList<h264Frame> smallKeyFrameList = new LinkedList<h264Frame>();
    private h264Frame lastSmallKeyFrame = null;
    private h264Frame lastSendSmallFrame = null;

    private int maxCapacity = 25*60*1;
    private boolean sendBigH264 = false;
    private boolean sendSmallH264 = false;
    private boolean beginRecord = false;

    private LocalWifiNetworkThread localWifiNetworkThread;

    public h264CacheQueue(){
        localWifiNetworkThread = new LocalWifiNetworkThread(this);
        localWifiNetworkThread.start();
        localWifiNetworkThread.searchServer();
    }

    //interface begin
    public void DirectServerConnected(){

    }
    public void DataReceived(short PacketID,byte[] data){
        if(PacketID == START_SEND_BIGDATA){
            if(beginRecord){
                if(!sendBigH264){
                    this.send(SEND_BIG_H264DATA,this.bigMetaData.pps);
                    this.send(SEND_BIG_H264DATA,this.bigMetaData.sps);
                    sendBigH264 = true;
                }
            }
        }else if(PacketID == STOP_SEND_BIGDATA){
            if(sendBigH264){
                sendBigH264 = false;
                this.lastSendBigFrame = null;
            }
        }
    }
    //interface end

    private void send(short packetID,byte[] data){
        localWifiNetworkThread.sendData(packetID,data);
    }

    public void setBigSPSPPS(byte[] pps,byte[] sps){
        this.bigMetaData.sps = sps;
        this.bigMetaData.pps = pps;
    }

    public void enterBigH264(byte[] data,boolean isKeyFrame){
        h264Frame frame = new h264Frame();
        frame.isKeyFrame = isKeyFrame;
        frame.timestamp = new Date().getTime()/1000;
        frame.frameData = data;

        //判断队列是否已满，满的话需要移除最久的帧，然后才能插入新的帧
        if(this.bigH264Queue.size() >=this.maxCapacity){
           h264Frame oldestframe = this.bigH264Queue.poll(); //删除头部元素
            if(oldestframe.isKeyFrame){
                this.bigKeyFrameList.poll();
            }
            this.bigH264Queue.offer(frame);
        }else{
            this.bigH264Queue.offer(frame);
        }

        //如果是关键帧，则记录下来，并存入关键帧队列
        if(isKeyFrame){
            this.lastBigKeyFrame = frame;
            this.bigKeyFrameList.offer(frame);
        }

        //收到第一帧后，设置开始录制的标记
        if(!beginRecord){
            beginRecord = true;
        }

        //是否需要发送到网络
        if(sendBigH264){
            if(this.lastSendBigFrame == null){
                //上一帧不存在，代表第一次发送，发送最近的一个关键帧，并记录下来
                this.send(SEND_BIG_H264DATA,this.lastBigKeyFrame.frameData);
                this.lastSendBigFrame = this.lastBigKeyFrame;
            }else{
                //获得当前要发送的帧
                int index = this.bigH264Queue.indexOf(this.lastSendBigFrame);
                h264Frame current = this.bigH264Queue.get(index+1);
                this.send(SEND_BIG_H264DATA,current.frameData);
                this.lastSendBigFrame = current;
            }
        }
    }

    public void setSmallSPSPPS(){

    }

    public void enterSmallH264(){

    }

    public void exit(){
        if(localWifiNetworkThread != null){
            localWifiNetworkThread.exit();
            try {
                localWifiNetworkThread.join();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            localWifiNetworkThread = null;
        }
    }

}
