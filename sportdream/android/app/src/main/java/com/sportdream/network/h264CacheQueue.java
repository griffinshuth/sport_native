package com.sportdream.network;

import android.util.Log;

import com.sportdream.DreamSDK.Delegate.LocalClientCoreDelegate;
import com.sportdream.DreamSDK.LocalClientCore;
import com.sportdream.H264AACHWEncode.Util;
import com.sportdream.Listeners.LocalCameraSocketListener;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedList;

import impl.underdark.transport.bluetooth.server.BtHacks;
import io.reactivex.internal.operators.maybe.MaybeHide;

/**
 * Created by lili on 2018/1/22.
 */

public class h264CacheQueue implements LocalWifiSocketHandler,LocalClientCoreDelegate {
    private boolean sendBigH264 = false;
    private boolean sendSmallH264 = false;
    private LocalWifiNetworkThread localWifiNetworkThread;
    private LocalCameraSocketListener cameraSocketListener;
    Boolean isDirectServerConnected = false;
    String  mDeviceID;
    int mRoomID;
    int CameraType;
    String CameraName;

    Boolean isHighlightServerConnected = false;
    Boolean canSendHighlightH264 = false;
    byte[]    mHighlightSPS;
    byte[]    mHighlightPPS;
    byte[]    mSmallSPS;
    byte[]    mSmallPPS;
    byte[]    mBigSPS;
    byte[]    mBigPPS;
    byte[]    mLastSmallIFrames;
    LocalClientCore mHighlightClient;
    String mHighlightIP;

    String mH264BigFile_path;
    String mH264SmallFile_path;
    String mMetaBigFile_path;
    String mMetaSmallFile_path;

    ArrayList<H264FrameMetaData> mMetaBigData = new ArrayList();
    ArrayList<H264FrameMetaData> mMetaSmallData = new ArrayList();
    //元数据临时变量，每次从文件系统中获得信息进行初始化
    int mBigFrameCount;               //编码的大流帧数
    int mSmallFrameCount;             //编码的小流帧数
    int lastBigIFrameIndex;               //上一个大流I帧的索引
    int lastSmallIFrameIndex;             //上一个小流I帧的索引
    long currentBigFileLength;             //当前大流视频文件大小，以字节为单位
    long currentSmallFileLength;           //当前小流视频文件大小，以字节为单位
    long mInitBigRelativeTime;      //以第一个大流I帧的绝对编码时间为初始值
    long mInitSmallRelativeTime;     //以第一个小流I帧的绝对编码时间为初始值
    int     mlastBigFrameRelativeTime;   //上一帧的相对时间
    int     mlastSmallFrameRelativeTime;  //上一帧的相对时间
    long mBeginServerAbsoluteTime;  //导播服务器绝对时间，所以的机位时间都以导播服务器为准
    long mBeginLocalAbsoluteTime;   //收到服务器时间同步包时的本机绝对时间


    public h264CacheQueue(String deviceID,int roomID,int cameraType,String cameraName,
                          String h264BigFile_path,String h264SmallFile_path,String metaBigFile_path,String metaSmallFile_path,
                          String highlightIP){
        mDeviceID = deviceID;
        mRoomID = roomID;
        CameraType = cameraType;
        CameraName = cameraName;
        mH264BigFile_path = h264BigFile_path;
        mH264SmallFile_path = h264SmallFile_path;
        mMetaBigFile_path = metaBigFile_path;
        mMetaSmallFile_path = metaSmallFile_path;
        mHighlightIP = highlightIP;

        mBigFrameCount = 0;               //编码的大流帧数
        mSmallFrameCount = 0;             //编码的小流帧数
        lastBigIFrameIndex = -1;               //上一个大流I帧的索引
        lastSmallIFrameIndex = -1;             //上一个小流I帧的索引
        currentBigFileLength = 0;             //当前大流视频文件大小
        currentSmallFileLength = 0;           //当前小流视频文件大小
        mInitBigRelativeTime = -1;      //以第一个大流I帧的绝对编码时间为初始值
        mInitSmallRelativeTime = -1;     //以第一个小流I帧的绝对编码时间为初始值
        mlastBigFrameRelativeTime = -1;   //上一帧的相对时间
        mlastSmallFrameRelativeTime = -1;  //上一帧的相对时间

        //读取大小流元文件数据
        File bigmetafile = new File(mMetaBigFile_path);
        File bigvideofile = new File(mH264BigFile_path);
        if(bigmetafile.exists() && bigvideofile.exists()){
            int bigmetafilelen = (int)bigmetafile.length();
            currentBigFileLength = bigvideofile.length();
            byte[] bigmetafilebuffer = new byte[bigmetafilelen];
            try{
                InputStream bigmetafilestream = new FileInputStream(bigmetafile);
                bigmetafilestream.read(bigmetafilebuffer);
                bigmetafilestream.close();
                //从文件字节缓冲区中构造元数据数组
                long accumulativeVideoFileLen = 0;
                int metaDataSize = H264FrameMetaData.size();
                mBigFrameCount = bigmetafilelen/metaDataSize;
                for(int i=0;i<mBigFrameCount;i++){
                    ByteBuffer byteBuffer = ByteBuffer.wrap(bigmetafilebuffer,i*metaDataSize,metaDataSize);
                    H264FrameMetaData metaData = H264FrameMetaData.getH264FrameMetaDataFromBytes(byteBuffer);
                    mMetaBigData.add(metaData);
                    accumulativeVideoFileLen += metaData.length;
                }
                if(accumulativeVideoFileLen != currentBigFileLength){
                    Log.i("sportdream","accumulativeVideoFileLen != currentBigFileLength");
                }

            }catch (FileNotFoundException e){
                e.printStackTrace();
            }catch (IOException e){
                e.printStackTrace();
            }

        }
        File smallmetafile = new File(mMetaSmallFile_path);
        File smallvideofile = new File(mH264SmallFile_path);
        if(smallmetafile.exists() && smallvideofile.exists()){
            int smallmetafilelen = (int)smallmetafile.length();
            currentSmallFileLength = smallvideofile.length();
            byte[] smallmetafilebuffer = new byte[smallmetafilelen];
            try{
                InputStream smallmetafilestream = new FileInputStream(smallmetafile);
                smallmetafilestream.read(smallmetafilebuffer);
                smallmetafilestream.close();
                //从文件字节缓冲区中构造元数据数组
                long accumulativeVideoFileLen = 0;
                int metaDataSize = H264FrameMetaData.size();
                mSmallFrameCount = smallmetafilelen/metaDataSize;
                for(int i=0;i<mSmallFrameCount;i++){
                    ByteBuffer byteBuffer = ByteBuffer.wrap(smallmetafilebuffer,i*metaDataSize,metaDataSize);
                    H264FrameMetaData metaData = H264FrameMetaData.getH264FrameMetaDataFromBytes(byteBuffer);
                    mMetaSmallData.add(metaData);
                    accumulativeVideoFileLen += metaData.length;
                }
                if(accumulativeVideoFileLen != currentSmallFileLength){
                    Log.i("sportdream","accumulativeVideoFileLen != currentSmallFileLength");
                }
            }catch (FileNotFoundException e){
                e.printStackTrace();
            }catch (IOException e){
                e.printStackTrace();
            }
        }
    }

    public void addResetListener(LocalCameraSocketListener listener){
        cameraSocketListener = listener;
        //导播服务器
        localWifiNetworkThread = new LocalWifiNetworkThread(this);
        localWifiNetworkThread.start();
        localWifiNetworkThread.searchServer();
        //集锦服务器
        mHighlightClient = new LocalClientCore();
        mHighlightClient.addDelegate(this);
        if(mHighlightIP != null){
            mHighlightClient.connectServer(mHighlightIP,4002);
        }
    }

    public void connectDirectServer(){
        if(isDirectServerConnected){
            return;
        }
        localWifiNetworkThread.searchServer();
    }

    public synchronized H264FrameMetaData getNewestSmallIFrame(){
        int index = mMetaSmallData.size()-1;
        while (index>=0){
            H264FrameMetaData metaData = mMetaSmallData.get(index);
            if(metaData.type == H264FrameMetaData.IFRAME){
                return metaData;
            }
            index--;
        }
        return null;
    }

    public synchronized H264FrameMetaData getFrontSmallIframeByIndex(int frameIndex){
        int index = frameIndex-1;
        while (index>=0){
            H264FrameMetaData metaData = mMetaSmallData.get(index);
            if(metaData.type == H264FrameMetaData.IFRAME){
                return metaData;
            }
            index--;
        }
        return null;
    }

    public synchronized H264FrameMetaData getFrontSmallIframebyIndexAndDistance(int frameIndex,int distance){
        H264FrameMetaData result = null;
        int n = distance;
        int index = frameIndex-1;
        while (index>=0){
            H264FrameMetaData metaData = mMetaSmallData.get(index);
            if(metaData.type == H264FrameMetaData.IFRAME){
                result = metaData;
                n--;
                if(n<=0){
                    break;
                }
            }
            index--;
        }
        return result;
    }

    public synchronized H264FrameMetaData getBackSmallframeByIndex(int frameIndex){
        int index = frameIndex+1;
        while (index < mMetaSmallData.size()){
            H264FrameMetaData metaData = mMetaSmallData.get(index);
            if(metaData.type == H264FrameMetaData.IFRAME){
                return metaData;
            }
            index++;
        }
        return null;
    }

    public synchronized H264FrameMetaData getBackSmallframeByIndexAndDistance(int frameIndex,int distance){
        H264FrameMetaData result = null;
        int n = distance;
        int index = frameIndex+1;
        int length = mMetaSmallData.size();
        while (index<length){
            H264FrameMetaData metaData = mMetaSmallData.get(index);
            if(metaData.type == H264FrameMetaData.IFRAME){
                result = metaData;
                n--;
                if(n<=0){
                    break;
                }
            }
            index++;
        }
        return result;
    }

    public synchronized H264FrameMetaData getNextSmallFrameByIndex(int frameIndex){
        int index = frameIndex+1;
        while (index<mMetaSmallData.size()){
            H264FrameMetaData metaData = mMetaSmallData.get(index);
            if(metaData.type != H264FrameMetaData.PPS && metaData.type != H264FrameMetaData.SPS){
                return metaData;
            }
            index++;
        }
        return null;
    }

    public byte[] getFrameDataFromSmallFile(long position, int  length){
        byte[] frame = new byte[length];
        Util.read(frame,(int)position,length,mH264SmallFile_path);
        return frame;
    }

    //delegate begin 集锦服务器回调
    public void LocalClientConnectFailed(){

    }
    public void LocalClientConnected(){
        isHighlightServerConnected = true;
        String json = "{\"id\":\"login\",\"deviceID\":\"%s\",\"type\":%d,\"name\":\"%s\",\"isSlowMotion\":%d}";
        String json_str = String.format(json,mDeviceID,CameraType,CameraName,false);
        mHighlightClient.send(PacketIDDef.JSON_MESSAGE,json_str.getBytes());
        cameraSocketListener.OnHighlightServerConnected();
    }
    public void LocalClientDisconnected(){
        isHighlightServerConnected = false;
        cameraSocketListener.OnHighlightServerDisconnected();
    }
    public void LocalClientDataReceived(short PacketID,byte[] data){
        if(PacketID == PacketIDDef.JSON_MESSAGE){
            String json_str = new String(data);
            Log.i("sportdream",json_str);
            try {
                JSONObject jObject  = new JSONObject(json_str);
                String json_id = jObject.getString("id");
                if(json_id.equals("highlight_startplay")){
                    Boolean state = jObject.getBoolean("state");
                    if(state){
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,mHighlightSPS);
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,mHighlightPPS);
                    }
                    canSendHighlightH264 = state;
                }else if(json_id.equals("initDecoder")){
                    mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,mHighlightSPS);
                    mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,mHighlightPPS);
                    String json = "{\"id\":\"initDecoder\",\"result\":\"%s\"}";
                    String json_result = String.format(json,"success");
                    mHighlightClient.send(PacketIDDef.JSON_MESSAGE,json_result.getBytes());
                }else if(json_id.equals("getNewestSmallIFrame")){
                    canSendHighlightH264 = false;
                    H264FrameMetaData metaData = null;
                    metaData = getNewestSmallIFrame();
                    if(metaData != null){
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,mHighlightSPS);
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,mHighlightPPS);
                        String json = "{\"id\":\"getNewestSmallIFrame\",\"type\":%d,\"absoluteTime\":%d,\"relativeTime\":%d,\"frameIndex\":%d,\"IFrameIndex\":%d,\"position\":%d,\"length\":%d,\"duration\":%d}";
                        String json_result = String.format(json,metaData.type,metaData.absoluteTime
                                ,metaData.relativeTime,metaData.frameIndex,metaData.IFrameIndex,metaData.position
                                ,metaData.length,metaData.duration);
                        mHighlightClient.send(PacketIDDef.JSON_MESSAGE,json_result.getBytes());
                        byte[] frameData = getFrameDataFromSmallFile(metaData.position+4,metaData.length-4);
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,frameData);
                    }else{

                    }
                }else if(json_id.equals("getNextSmallFrame")){
                    int frameindex = jObject.getInt("frameindex");
                    H264FrameMetaData metaData = getNextSmallFrameByIndex(frameindex);
                    if(metaData != null){
                        String json = "{\"id\":\"getNextSmallFrame\",\"type\":%d,\"absoluteTime\":%d,\"relativeTime\":%d,\"frameIndex\":%d,\"IFrameIndex\":%d,\"position\":%d,\"length\":%d,\"duration\":%d}";
                        String json_result = String.format(json,metaData.type,metaData.absoluteTime
                                ,metaData.relativeTime,metaData.frameIndex,metaData.IFrameIndex,metaData.position
                                ,metaData.length,metaData.duration);
                        mHighlightClient.send(PacketIDDef.JSON_MESSAGE,json_result.getBytes());
                        byte[] frameData = getFrameDataFromSmallFile(metaData.position+4,metaData.length-4);
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,frameData);
                    }
                }else if(json_id.equals("seekBackIFrame")){
                    H264FrameMetaData metaData = null;
                    int frameindex = jObject.getInt("frameindex");
                    int interval = jObject.getInt("interval");
                    metaData = getBackSmallframeByIndexAndDistance(frameindex,interval);
                    if(metaData != null){
                        String json = "{\"id\":\"seekBackIFrame\",\"type\":%d,\"absoluteTime\":%d,\"relativeTime\":%d,\"frameIndex\":%d,\"IFrameIndex\":%d,\"position\":%d,\"length\":%d,\"duration\":%d}";
                        String json_result = String.format(json,metaData.type,metaData.absoluteTime
                                ,metaData.relativeTime,metaData.frameIndex,metaData.IFrameIndex,metaData.position
                                ,metaData.length,metaData.duration);
                        mHighlightClient.send(PacketIDDef.JSON_MESSAGE,json_result.getBytes());
                        byte[] frameData = getFrameDataFromSmallFile(metaData.position+4,metaData.length-4);
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,frameData);
                    }else{

                    }
                }else if(json_id.equals("seekFrontIFrame")){
                    H264FrameMetaData metaData = null;
                    int frameindex = jObject.getInt("frameindex");
                    int interval = jObject.getInt("interval");
                    metaData = getFrontSmallIframebyIndexAndDistance(frameindex,interval);
                    if(metaData != null){
                        String json = "{\"id\":\"seekFrontIFrame\",\"type\":%d,\"absoluteTime\":%d,\"relativeTime\":%d,\"frameIndex\":%d,\"IFrameIndex\":%d,\"position\":%d,\"length\":%d,\"duration\":%d}";
                        String json_result = String.format(json,metaData.type,metaData.absoluteTime
                                ,metaData.relativeTime,metaData.frameIndex,metaData.IFrameIndex,metaData.position
                                ,metaData.length,metaData.duration);
                        mHighlightClient.send(PacketIDDef.JSON_MESSAGE,json_result.getBytes());
                        byte[] frameData = getFrameDataFromSmallFile(metaData.position+4,metaData.length-4);
                        mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,frameData);
                    }else{
                        //到达文件头部，给服务器发送信息

                    }
                }
            }catch (JSONException e){
                e.printStackTrace();
            }
        }
    }
    //degegate end

    //interface begin 导播服务器回调
    public void DirectServerConnected(){
        isDirectServerConnected = true;
        cameraSocketListener.OnDirectServerConnected();
        //发送登录信息
        String json = "{\"id\":\"localCameraLogin\",\"deviceID\":\"%s\",\"type\":%d,\"name\":\"%s\",\"subtype\":%d,\"isSlowMotion\":%d}";
        String json_str = String.format(json,mDeviceID,CameraType,CameraName,-1,false);
        send(PacketIDDef.JSON_MESSAGE,json_str.getBytes());
    }
    public void DirectServerDisconnected(){
        isDirectServerConnected = false;
        cameraSocketListener.OnDirectServerDisconnected();
    }
    public void DataReceived(short PacketID,byte[] data){
        if(PacketID == PacketIDDef.START_SEND_BIGDATA){
                if(!sendBigH264){
                    cameraSocketListener.OnMediaCodecReset(true);
                    this.send(PacketIDDef.SEND_BIG_H264DATA,mBigPPS);
                    this.send(PacketIDDef.SEND_BIG_H264DATA,mBigSPS);
                    sendBigH264 = true;
                }

        }else if(PacketID == PacketIDDef.STOP_SEND_BIGDATA){
            if(sendBigH264){
                sendBigH264 = false;
            }
        }else if(PacketID == PacketIDDef.START_SEND_SMALLDATA){
            if(!sendSmallH264){
                cameraSocketListener.OnMediaCodecReset(false);
                this.send(PacketIDDef.SEND_SMALL_H264SDATA,mSmallPPS);
                this.send(PacketIDDef.SEND_SMALL_H264SDATA,mSmallSPS);
                sendSmallH264 = true;
            }
        }else if(PacketID == PacketIDDef.STOP_SEND_SMALLDATA){
            if(sendSmallH264){
                sendSmallH264 = false;
            }
        }else if(PacketID == PacketIDDef.JSON_MESSAGE){
            String json_str = new String(data);
            try {
                JSONObject jObject  = new JSONObject(json_str);
                String json_id = jObject.getString("id");
                if(json_id.equals("getHighlightServerIP")){
                    boolean isConnect = jObject.getBoolean("isConnect");
                    if(isConnect){
                        String ip = jObject.getString("ip");
                        cameraSocketListener.OnHighlightServerInfo("找到集锦服务器，开始连接");
                        mHighlightClient.connectServer(ip,4002);
                    }else{
                        cameraSocketListener.OnHighlightServerInfo("集锦服务器没有启动，请稍后重试");
                    }
                }
            }catch (JSONException e){
                e.printStackTrace();
            }
        }
    }
    //interface end

    public void getHighlightServerIPAndConnect(){
        if(isHighlightServerConnected){
            return;
        }
        //发送登录信息
        String json = "{\"id\":\"getHighlightServerIP\"}";
        send(PacketIDDef.JSON_MESSAGE,json.getBytes());
    }

    private void send(short packetID,byte[] data){
        if(localWifiNetworkThread != null){
            localWifiNetworkThread.sendData(packetID,data);
        }
    }

    //导播服务器相关接口
    public void setBigSPSPPS(byte[] pps,byte[] sps){
        mBigSPS = sps;
        mBigPPS = pps;
        saveBigSPSPPS(sps,pps);
        if(isDirectServerConnected && sendBigH264){
            this.send(PacketIDDef.SEND_BIG_H264DATA,pps);
            this.send(PacketIDDef.SEND_BIG_H264DATA,sps);
        }
    }

    public void enterBigH264(byte[] data,boolean isKeyFrame){
        saveBigH264(data,isKeyFrame);
        if(isDirectServerConnected && sendBigH264){
            this.send(PacketIDDef.SEND_BIG_H264DATA,data);
        }
    }

    public void setSmallSPSPPS(byte[] pps,byte[] sps){
        mSmallPPS = pps;
        mSmallSPS = sps;
        saveSmallSPSPPS(sps,pps);
        if(isDirectServerConnected && sendSmallH264){
            this.send(PacketIDDef.SEND_SMALL_H264SDATA,pps);
            this.send(PacketIDDef.SEND_SMALL_H264SDATA,sps);
        }
    }

    public void enterSmallH264(byte[] data,boolean isKeyFrame){
        saveSmallH264(data,isKeyFrame);
        if(isDirectServerConnected && sendSmallH264){
            this.send(PacketIDDef.SEND_SMALL_H264SDATA,data);
        }
    }

    //集锦服务器相关接口
    public void setSPSPPSToHighlightServer(byte[] pps,byte[] sps){
        mHighlightSPS = sps;
        mHighlightPPS = pps;
    }

    public void enterH264DataToHighlightServer(byte[] data,boolean isKeyFrame){
        if(isKeyFrame){
            mLastSmallIFrames = data;
        }
        if(isHighlightServerConnected && canSendHighlightH264){
            mHighlightClient.send(PacketIDDef.SEND_SMALL_H264SDATA,data);
        }
    }

    //本地文件接口
    private void saveBigSPSPPS(byte[] sps,byte[] pps){
        long currentTimeMills = new Date().getTime();
        byte[] header = new byte[4];
        header[0] = 0;
        header[1] = 0;
        header[2] = 0;
        header[3] = 1;
        //保存元数据
        H264FrameMetaData spsMetaData = new H264FrameMetaData();
        spsMetaData.type = 2;
        spsMetaData.absoluteTime = currentTimeMills;
        spsMetaData.relativeTime = -1;
        spsMetaData.frameIndex = mBigFrameCount;
        mBigFrameCount++;
        spsMetaData.IFrameIndex = -1;
        spsMetaData.position = currentBigFileLength;
        spsMetaData.length = (4+sps.length);
        spsMetaData.duration = 0;
        currentBigFileLength += (4+sps.length);
        mMetaBigData.add(spsMetaData);
        byte[] spsMetaBuffer = H264FrameMetaData.saveH264FrameMetaDataToBytes(spsMetaData);
        Util.save(spsMetaBuffer,0,spsMetaBuffer.length,mMetaBigFile_path,true);

        //保存视频数据
        Util.save(header,0,4,mH264BigFile_path,true);
        Util.save(sps,0,sps.length,mH264BigFile_path,true);

        //保存元数据
        H264FrameMetaData ppsMetaData = new H264FrameMetaData();
        ppsMetaData.type = 1;
        ppsMetaData.absoluteTime = currentTimeMills;
        ppsMetaData.relativeTime = -1;
        ppsMetaData.frameIndex = mBigFrameCount;
        mBigFrameCount++;
        ppsMetaData.IFrameIndex = -1;
        ppsMetaData.position = currentBigFileLength;
        ppsMetaData.length = (4+pps.length);
        ppsMetaData.duration = 0;
        currentBigFileLength += (4+pps.length);
        mMetaBigData.add(ppsMetaData);
        byte[] ppsMetaBuffer = H264FrameMetaData.saveH264FrameMetaDataToBytes(ppsMetaData);
        Util.save(ppsMetaBuffer,0,ppsMetaBuffer.length,mMetaBigFile_path,true);

        Util.save(header,0,4,mH264BigFile_path,true);
        Util.save(pps,0,pps.length,mH264BigFile_path,true);
    }
    private void saveBigH264(byte[] bigdata,boolean iskeyframe){
        byte[] header = new byte[4];
        header[0] = 0;
        header[1] = 0;
        header[2] = 0;
        header[3] = 1;
        long currentTimeMills = new Date().getTime();
        if(mInitBigRelativeTime == -1){
            //保存第一帧到来的绝对时间
            mInitBigRelativeTime = currentTimeMills;
        }
        int relativeTime = (int)(currentTimeMills - mInitBigRelativeTime);
        H264FrameMetaData metaData = new H264FrameMetaData();
        if(iskeyframe){
            metaData.type = 3;
        }else{
            metaData.type = 4;
        }
        metaData.absoluteTime = currentTimeMills;
        metaData.relativeTime = relativeTime;
        metaData.frameIndex = mBigFrameCount;
        if(iskeyframe){
            lastBigIFrameIndex = mBigFrameCount;
        }
        mBigFrameCount++;
        if(iskeyframe)
            metaData.IFrameIndex = -1;
        else
            metaData.IFrameIndex = lastBigIFrameIndex;

        metaData.position = currentBigFileLength;
        metaData.length = (4+bigdata.length);
        if(mlastBigFrameRelativeTime == -1){
            metaData.duration = 0;
        }else{
            metaData.duration = (short)(relativeTime - mlastBigFrameRelativeTime);
        }
        currentBigFileLength += (4+bigdata.length);
        //保存本帧相对时间，供下一帧计算持续时间
        mlastBigFrameRelativeTime = relativeTime;
        mMetaBigData.add(metaData);
        byte[] metaDataBuffer = H264FrameMetaData.saveH264FrameMetaDataToBytes(metaData);
        Util.save(metaDataBuffer,0,metaDataBuffer.length,mMetaBigFile_path,true);

        Util.save(header,0,4,mH264BigFile_path,true);
        Util.save(bigdata,0,bigdata.length,mH264BigFile_path,true);
    }

    private synchronized void saveSmallSPSPPS(byte[] sps,byte[] pps){
        long currentTimeMills = new Date().getTime();
        byte[] header = new byte[4];
        header[0] = 0;
        header[1] = 0;
        header[2] = 0;
        header[3] = 1;

        //保存元数据
        H264FrameMetaData spsMetaData = new H264FrameMetaData();
        spsMetaData.type = 2;
        spsMetaData.absoluteTime = currentTimeMills;
        spsMetaData.relativeTime = -1;
        spsMetaData.frameIndex = mSmallFrameCount;
        mSmallFrameCount++;
        spsMetaData.IFrameIndex = -1;
        spsMetaData.position = currentSmallFileLength;
        spsMetaData.length = (4+sps.length);
        spsMetaData.duration = 0;
        currentSmallFileLength += (4+sps.length);
        mMetaSmallData.add(spsMetaData);
        byte[] spsMetaBuffer = H264FrameMetaData.saveH264FrameMetaDataToBytes(spsMetaData);
        Util.save(spsMetaBuffer,0,spsMetaBuffer.length,mMetaSmallFile_path,true);

        Util.save(header,0,4,mH264SmallFile_path,true);
        Util.save(sps,0,sps.length,mH264SmallFile_path,true);

        //保存元数据
        H264FrameMetaData ppsMetaData = new H264FrameMetaData();
        ppsMetaData.type = 1;
        ppsMetaData.absoluteTime = currentTimeMills;
        ppsMetaData.relativeTime = -1;
        ppsMetaData.frameIndex = mSmallFrameCount;
        mSmallFrameCount++;
        ppsMetaData.IFrameIndex = -1;
        ppsMetaData.position = currentSmallFileLength;
        ppsMetaData.length = (4+pps.length);
        ppsMetaData.duration = 0;
        currentSmallFileLength += (4+pps.length);
        mMetaSmallData.add(ppsMetaData);
        byte[] ppsMetaBuffer = H264FrameMetaData.saveH264FrameMetaDataToBytes(ppsMetaData);
        Util.save(ppsMetaBuffer,0,ppsMetaBuffer.length,mMetaSmallFile_path,true);

        Util.save(header,0,4,mH264SmallFile_path,true);
        Util.save(pps,0,pps.length,mH264SmallFile_path,true);
    }
    private synchronized void saveSmallH264(byte[] smalldata,boolean iskeyframe){
        byte[] header = new byte[4];
        header[0] = 0;
        header[1] = 0;
        header[2] = 0;
        header[3] = 1;
        long currentTimeMills = new Date().getTime();
        if(mInitSmallRelativeTime == -1){
            //保存第一帧到来的绝对时间
            mInitSmallRelativeTime = currentTimeMills;
        }
        int relativeTime = (int)(currentTimeMills - mInitSmallRelativeTime);
        H264FrameMetaData metaData = new H264FrameMetaData();
        if(iskeyframe){
            metaData.type = 3;
        }else{
            metaData.type = 4;
        }
        metaData.absoluteTime = currentTimeMills;
        metaData.relativeTime = relativeTime;
        metaData.frameIndex = mSmallFrameCount;
        if(iskeyframe){
            lastSmallIFrameIndex = mSmallFrameCount;
        }
        mSmallFrameCount++;
        if(iskeyframe)
            metaData.IFrameIndex = -1;
        else
            metaData.IFrameIndex = lastSmallIFrameIndex;

        metaData.position = currentSmallFileLength;
        metaData.length = (4+smalldata.length);
        if(mlastSmallFrameRelativeTime == -1){
            metaData.duration = 0;
        }else{
            metaData.duration = (short)(relativeTime - mlastSmallFrameRelativeTime);
        }
        currentSmallFileLength += (4+smalldata.length);
        //保存本帧相对时间，供下一帧计算持续时间
        mlastSmallFrameRelativeTime = relativeTime;
        mMetaSmallData.add(metaData);
        byte[] metaDataBuffer = H264FrameMetaData.saveH264FrameMetaDataToBytes(metaData);
        Util.save(metaDataBuffer,0,metaDataBuffer.length,mMetaSmallFile_path,true);

        Util.save(header,0,4,mH264SmallFile_path,true);
        Util.save(smalldata,0,smalldata.length,mH264SmallFile_path,true);
    }

    public void exit(){
        mHighlightClient.disconnect();
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
