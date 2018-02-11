package com.sportdream.DreamSDK;

import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.provider.MediaStore;
import android.util.Log;

import com.sportdream.DreamSDK.Delegate.AACEncoderDelegate;

import java.io.IOException;
import java.nio.ByteBuffer;

/**
 * Created by lili on 2018/2/3.
 */

public class AACEncoder {
    private MediaCodec mAACCodec;
    private int mSampleRate = 44100;
    private int channels = 1;
    private int mBitRate = 100000;
    AACEncoderDelegate delegate;
    public AACEncoder(){

    }

    public void setDelegate(AACEncoderDelegate delegate){
        this.delegate = delegate;
    }

    private void addADTSToPacket(byte[] data,int packetLen){
        data[0] = (byte)0xFF;
        data[1] = (byte)0xF9;
        int profile = 2; //AAC LC;
        int freqIdx = 4; //44.1kHz
        int chanCfg = 1; //单声道

        data[2] = (byte)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
        data[3] = (byte)(((chanCfg&3)<<6) + (packetLen>>11));
        data[4] = (byte)((packetLen&0x7FF) >> 3);
        data[5] = (byte)(((packetLen&7)<<5) + 0x1F);
        data[6] = (byte)0xFC;
    }

    public void init(){
        try{
            mAACCodec = MediaCodec.createEncoderByType("audio/mp4a-latm");
        }catch (IOException e){
            e.printStackTrace();
        }

        MediaFormat encodeFormat = MediaFormat.createAudioFormat("audio/mp4a-latm",mSampleRate,channels);
        encodeFormat.setInteger(MediaFormat.KEY_BIT_RATE,mBitRate);
        encodeFormat.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC);
        encodeFormat.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE,10*1024);
        mAACCodec.configure(encodeFormat,null,null,MediaCodec.CONFIGURE_FLAG_ENCODE);
        mAACCodec.start();
    }

    public  void encode(byte[] pcmData){
        ByteBuffer[] inputBuffers = mAACCodec.getInputBuffers();
        ByteBuffer[] outputBuffers = mAACCodec.getOutputBuffers();
        int inputBufferIndex = mAACCodec.dequeueInputBuffer(-1);
        if(inputBufferIndex>=0){
            ByteBuffer inputBuffer = inputBuffers[inputBufferIndex];
            inputBuffer.clear();
            inputBuffer.put(pcmData);
            long time = System.nanoTime();
            int len = inputBuffer.position();
            mAACCodec.queueInputBuffer(inputBufferIndex,0,len,time,0);
            //提取转换后的数据
            MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
            int outputIndex = mAACCodec.dequeueOutputBuffer(info,0);
            while (outputIndex>=0){
                ByteBuffer outputBuffer = outputBuffers[outputIndex];
                //包含ADTS
                int outPacketSize = info.size+7;
                outputBuffer.position(info.offset);
                outputBuffer.limit(info.offset+info.size);
                byte[] dataWithADTS = new byte[outPacketSize];
                addADTSToPacket(dataWithADTS,outPacketSize);
                outputBuffer.get(dataWithADTS,7,info.size);
                delegate.dataWithADTSFromAACEncoder(dataWithADTS);
                //不包含ADTS
                outputBuffer.position(info.offset);
                outputBuffer.limit(info.offset+info.size);
                byte[] dataWithoutADTS = new byte[info.size];
                outputBuffer.get(dataWithoutADTS);
                delegate.dataWithoutADTSFromAACEncoder(dataWithoutADTS);

                mAACCodec.releaseOutputBuffer(outputIndex,false);
                outputIndex = mAACCodec.dequeueOutputBuffer(info,0);
            }
        }
    }

    public void destroy(){
        if(mAACCodec != null){
            mAACCodec.stop();
            mAACCodec.release();
        }
    }
}
