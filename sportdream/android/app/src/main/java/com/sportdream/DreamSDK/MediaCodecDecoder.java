package com.sportdream.DreamSDK;

import android.annotation.SuppressLint;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.view.Surface;

import java.nio.ByteBuffer;

/**
 * Created by lili on 2018/5/2.
 */

public class MediaCodecDecoder {
    private static final String VIDEO_MIME_TYPE = "video/avc";
    private MediaFormat m_format = null;
    private Surface m_surface = null;
    private MediaCodec.BufferInfo m_bufferInfo = null;
    private MediaCodec m_decoder = null;
    private boolean m_decoderStarted = false;
    ByteBuffer[] m_decoderInputBuffers = null;
    private boolean m_inputBufferQueued = false;

    private int mWidth;
    private int mHeight;
    //初始化都为false，第一次收到sps和pps后，都设置为true，然后初始化编码器，编码器初始化完毕后，马上都置为false，如果收到新的sps pps 后，则使用新的sps pps 重启解码器
    private Boolean isReceiveSPS = false;
    private Boolean isReceivePPS = false;
    private byte[]  mSps;
    private byte[]  mPps;

    public MediaCodecDecoder(int width,int height){
        m_bufferInfo = new MediaCodec.BufferInfo();
        mWidth = width;
        mHeight = height;
    }

    public void setSurface(Surface surface){
        m_surface = surface;
    }

    public void frameProcess(byte[] data,int length){
        if(data[0] ==0&&data[1]==0&&data[2]==0&&data[3]==1&&((data[4]& 0x1F)==0x07)){
            //sps
            mSps = data;
            isReceiveSPS = true;
            if(isReceiveSPS && isReceivePPS){
                //CleanupDecoder();
                if(!m_decoderStarted){
                    CreateVideoDecoder();
                }else{
                    resetVideoDecoder();
                }
            }
        }else if(data[0] ==0&&data[1]==0&&data[2]==0&&data[3]==1&&((data[4]& 0x1F)==0x08)){
            //pps
            mPps = data;
            isReceivePPS = true;
            if(isReceiveSPS && isReceivePPS){
                //CleanupDecoder();
                if(!m_decoderStarted){
                    CreateVideoDecoder();
                }else{
                    resetVideoDecoder();
                }
            }
        }else if(data[0] == 0 && data[1] == 0 && data[2] == 0 && data[3] == 1 && ((data[4]& 0x1F)==0x05)){
            //I frame
            DecodeFrame(data,length);
        }else{
            DecodeFrame(data,length);
        }
    }

    private Boolean CreateVideoDecoder()
    {
        m_format = MediaFormat.createVideoFormat(VIDEO_MIME_TYPE, mWidth, mHeight);
        m_format.setByteBuffer("csd-0", ByteBuffer.wrap(mSps));
        m_format.setByteBuffer("csd-1", ByteBuffer.wrap(mPps));
        if (android.os.Build.VERSION.SDK_INT == 16) {
            // NOTE: some android 4.1 devices (such as samsung GT-I8552) will
            // crash in MediaCodec.configure
            // if we don't set MediaFormat.KEY_MAX_INPUT_SIZE.
            // Please refer to
            // http://stackoverflow.com/questions/22457623/surfacetextures-onframeavailable-method-always-called-too-late
            m_format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 0);
        }

        try {
            m_decoder = MediaCodec.createDecoderByType(VIDEO_MIME_TYPE);
            m_decoder.configure(m_format, m_surface, null, 0);
            m_decoder.start();
            m_decoderStarted = true;

            // Retrieve the set of input buffers
            m_decoderInputBuffers = m_decoder.getInputBuffers();
        } catch (Exception e) {
            e.printStackTrace();
            CleanupDecoder();
            return false;
        }

        isReceiveSPS = false;
        isReceivePPS = false;

        return true;
    }

    @SuppressLint("NewApi")
    private void resetVideoDecoder(){
        m_decoder.reset();
        m_format.setByteBuffer("csd-0", ByteBuffer.wrap(mSps));
        m_format.setByteBuffer("csd-1", ByteBuffer.wrap(mPps));
        m_decoder.configure(m_format,m_surface,null,0);
        m_decoder.start();
        m_decoderInputBuffers = m_decoder.getInputBuffers();
        isReceiveSPS = false;
        isReceivePPS = false;
    }

    private void CleanupDecoder() {
        if (m_decoder != null) {
            if (m_decoderStarted) {
                try {
                    if (m_inputBufferQueued) {
                        m_decoder.flush();
                        m_inputBufferQueued = false;
                    }
                    m_decoder.stop();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                m_decoderStarted = false;
                m_decoderInputBuffers = null;
            }
            m_decoder.release();
            m_decoder = null;
        }
    }

    private void DecodeFrame(byte[] frameData, int inputSize /*, long timeStamp*/) {
        final int TIMEOUT_USEC = 10*1000;
        final int inputBufIndex = m_decoder.dequeueInputBuffer(TIMEOUT_USEC);
        if (inputBufIndex >= 0) {
            ByteBuffer inputBuf = m_decoderInputBuffers[inputBufIndex];
            inputBuf.clear();
            inputBuf.put(frameData, 0, inputSize);
            m_decoder.queueInputBuffer(inputBufIndex, 0, inputSize, System.nanoTime()/1000, 0);
        }

        final int decoderStatus = m_decoder.dequeueOutputBuffer(m_bufferInfo, TIMEOUT_USEC);
        if (decoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
            // No output available yet
        } else if (decoderStatus == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
            // Not important for us, since we're using Surface
        } else if (decoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {

        } else if (decoderStatus < 0) {

        } else { // decoderStatus >= 0
            ByteBuffer[] outputbuffers = m_decoder.getOutputBuffers();
            ByteBuffer outputBuffer = outputbuffers[decoderStatus];
            byte[] outData = new byte[m_bufferInfo.size];
            outputBuffer.get(outData);
            m_decoder.releaseOutputBuffer(decoderStatus, true);
        }
    }
}



