package com.sportdream.H264AACHWEncode;

import android.app.Activity;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.ImageFormat;
import android.hardware.Camera;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Environment;
import android.os.Looper;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.Toast;

import com.koushikdutta.async.AsyncDatagramSocket;
import com.koushikdutta.async.*;
import com.koushikdutta.async.AsyncServerSocket;
import com.koushikdutta.async.AsyncSocket;
import com.koushikdutta.async.ByteBufferList;
import com.koushikdutta.async.DataEmitter;
import com.koushikdutta.async.callback.CompletedCallback;
import com.koushikdutta.async.callback.ConnectCallback;
import com.koushikdutta.async.callback.DataCallback;
import com.koushikdutta.async.callback.ListenCallback;
import com.sportdream.R;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.util.Iterator;
import java.util.List;
import android.util.Log;
import com.sportdream.nativec.udp;
import com.sportdream.network.BufferedPacketInfo;
import com.sportdream.network.LocalWifiNetworkThread;
import com.sportdream.network.LocalWifiSocketHandler;
import com.sportdream.network.SocketBuffer;
import com.sportdream.network.h264CacheQueue;

/**
 * Created by lili on 2017/10/8.
 */

@SuppressWarnings("deprecation")
public class RecordActivity extends Activity implements SurfaceHolder.Callback {
    String path = Environment.getExternalStorageDirectory()+"/sportdream.h264";
    int width = 1280,height=720;
    int framerate,bitrate;
    int mCameraId = Camera.CameraInfo.CAMERA_FACING_BACK;
    MediaCodec mMediaCodec;
    SurfaceView surfaceView;
    SurfaceHolder surfaceHolder;
    Camera mCamera;
    EncoderDebugger debugger;
    NV21Convertor mConvertor;
    Button btnSwitch;
    boolean startRecord = false;
    byte[] cameraBuffer = null;  //摄像头采集的每帧数据的缓存

    private h264CacheQueue mCacheQueue;

    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);//横屏
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
        ,WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.record_main);

        if(getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE){
            //---landscape mode---
            btnSwitch = (Button)findViewById(R.id.btn_switch);
            surfaceView = (SurfaceView)findViewById(R.id.sv_surfaceview);
            surfaceView.getHolder().addCallback(this);
            surfaceView.getHolder().setFixedSize(getResources().getDisplayMetrics().widthPixels,
                    getResources().getDisplayMetrics().heightPixels);
            debugger = EncoderDebugger.debug(getApplicationContext(),width,height);
            mConvertor = debugger.getNV21Convertor();
            initMediaCodec();
            mCacheQueue = new h264CacheQueue();
            this.startRecord = true;
            btnSwitch.setText("停止");
        }
        Button broastcast = (Button)findViewById(R.id.broadcast);
        broastcast.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

            }
        });
    }

    private void initMediaCodec(){
        int dgree = getDgree();
        framerate = 25;
        bitrate = 2*width*height*framerate/25;

        try{
            mMediaCodec = MediaCodec.createEncoderByType("video/avc"); //MediaCodec.createByCodecName(debugger.getEncoderName());
            MediaFormat mediaFormat;
            if(dgree == 0){
                mediaFormat = MediaFormat.createVideoFormat("video/avc",height,width);
            }else{
                mediaFormat = MediaFormat.createVideoFormat("video/avc",width,height);
            }
            mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE,bitrate);
            mediaFormat.setInteger(MediaFormat.KEY_FRAME_RATE,framerate);
            mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT,debugger.getEncoderColorFormat());
            mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL,2);
            mMediaCodec.configure(mediaFormat,null,null,MediaCodec.CONFIGURE_FLAG_ENCODE);
            mMediaCodec.start();
        }catch (IOException e){
            e.printStackTrace();
        }
    }

    public static int[] determineMaximumSupportedFramerate(Camera.Parameters parameters){
        int[] maxFps = new int[]{0,0};
        List<int[]> supportedFpsRanges = parameters.getSupportedPreviewFpsRange();
        for(Iterator<int[]> it = supportedFpsRanges.iterator();it.hasNext();){
            int[] interval = it.next();
            if(interval[1] > maxFps[1] || (interval[0]>maxFps[0]&&interval[1] == maxFps[1])){
                maxFps = interval;
            }
        }
        return maxFps;
    }

    //
    private int getDgree(){
        int rotation = getWindowManager().getDefaultDisplay().getRotation();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0:
                degrees = 0;
                break; // Natural orientation
            case Surface.ROTATION_90:
                degrees = 90;
                break; // Landscape left
            case Surface.ROTATION_180:
                degrees = 180;
                break;// Upside down
            case Surface.ROTATION_270:
                degrees = 270;
                break;// Landscape right
        }
        return degrees;
    }

    private boolean createCamera(SurfaceHolder surfaceHolder){
        try{
            mCamera = Camera.open(mCameraId);
            Camera.Parameters parameters = mCamera.getParameters();
            int[] max = determineMaximumSupportedFramerate(parameters);
            Camera.CameraInfo camInfo = new Camera.CameraInfo();
            Camera.getCameraInfo(mCameraId,camInfo);
            int cameraRotationOffset = camInfo.orientation;
            int rotate = (360+cameraRotationOffset-getDgree())%360;
            parameters.setRotation(rotate);
            parameters.setPreviewFormat(ImageFormat.NV21);
            List<Camera.Size> sizes = parameters.getSupportedPreviewSizes();
            parameters.setPreviewSize(width,height);
            parameters.setPreviewFpsRange(max[0],max[1]);
            mCamera.setParameters(parameters);
            mCamera.autoFocus(null);
            int displayRotation;
            displayRotation = (cameraRotationOffset-getDgree()+360)%360;
            mCamera.setDisplayOrientation(displayRotation);
            mCamera.setPreviewDisplay(surfaceHolder);
            Log.i("sportdream","maxfps:"+max[1]);
            return true;

        }catch (Exception e){
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            String stack = sw.toString();
            Toast.makeText(this, stack, Toast.LENGTH_LONG).show();
            destroyCamera();
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder){
        surfaceHolder = holder;
        createCamera(surfaceHolder);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder,int format,int width,int height){
        startPreview();
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder){
        stopPreview();
        destroyCamera();
    }

    Camera.PreviewCallback previewCallback = new Camera.PreviewCallback(){
        @Override
        public void onPreviewFrame(byte[] data,Camera camera){
            //Log.i("sportdream","this.startRecord:"+startRecord);
            if(cameraBuffer == null){
                cameraBuffer = new byte[data.length];
            }
                encodeH264(data);
        }
    };

    private void encodeH264(byte[] data){
        if(!this.startRecord){
            mCamera.addCallbackBuffer(cameraBuffer);
            return;
        }
        byte[] mPpsSps = new byte[0];
        byte[] buffer;
        ByteBuffer[] inputBuffers = mMediaCodec.getInputBuffers();
        ByteBuffer[] outputBuffers = mMediaCodec.getOutputBuffers();
        Camera.Size previewSize = mCamera.getParameters().getPreviewSize();
        if(getDgree() == 0){
            buffer = Util.rotateNV21Degree90(data,previewSize.width,previewSize.height);
        }else{
            buffer = data;
        }
        try{
            int bufferIndex = mMediaCodec.dequeueInputBuffer(5000000);
            if(bufferIndex >= 0){
                inputBuffers[bufferIndex].clear();
                mConvertor.convert(buffer,inputBuffers[bufferIndex]);
                mMediaCodec.queueInputBuffer(bufferIndex,0,inputBuffers[bufferIndex].position()
                        ,System.nanoTime()/1000,0);
                MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
                int outputBufferIndex = mMediaCodec.dequeueOutputBuffer(bufferInfo,0);
                while (outputBufferIndex>=0){
                    ByteBuffer outputBuffer = outputBuffers[outputBufferIndex];
                    byte[] outData = new byte[bufferInfo.size];
                    Log.i("sportdream","frame length:"+bufferInfo.size);
                    outputBuffer.get(outData);
                    //sps
                    if(outData[0] ==0&&outData[1]==0&&outData[2]==0&&outData[3]==1&&((outData[4]& 0x1F)==0x07)){
                        //寻找pps的头部
                        for(int i=5;i<outData.length-4;i++){
                            if(outData[i] ==0&&outData[i+1]==0&&outData[i+2]==0&&outData[i+3]==1&&((outData[i+4]& 0x1F)==0x08)){

                                int spslen = i;
                                int ppslen = outData.length-spslen;
                                byte[] sps = new byte[spslen-4];
                                System.arraycopy(outData,4,sps,0,spslen-4);
                                byte[] pps = new byte[ppslen-4];
                                System.arraycopy(outData,i+4,pps,0,ppslen-4);
                                //udpSendBytes(directorServerIP,9888,sps);
                                //udpSendBytes(directorServerIP,9888,pps);
                                mCacheQueue.setBigSPSPPS(pps,sps);
                                break;
                            }
                        }
                    }else{
                        //udpSendBytes(directorServerIP,9888,outData);
                        boolean isKeyframe = false;
                        int type = (outData[4]& 0x1F);
                        Log.w("sportdream","nalu type:"+type);
                        if(outData[0] == 0 && outData[1] == 0 && outData[2] == 0 && outData[3] == 1 && ((outData[4]& 0x1F)==0x05)){
                            isKeyframe = true;
                        }
                        byte[] dataWithHeader = new byte[outData.length-4];
                        System.arraycopy(outData,4,dataWithHeader,0,outData.length-4);

                        mCacheQueue.enterBigH264(dataWithHeader,isKeyframe);
                    }

                    //记录pps和sps
                    /*if(outData[0] ==0&&outData[1]==0&&outData[2]==0&&outData[3]==1&&outData[4]==103){
                        mPpsSps = outData;
                    }else if(outData[0] == 0 && outData[1] == 0 && outData[2] == 0 && outData[3] == 1 && outData[4] == 101){
                        //在关键帧前面加上pps和sps数据
                        byte[] iframeData = new byte[mPpsSps.length+outData.length];
                        System.arraycopy(mPpsSps,0,iframeData,0,mPpsSps.length);
                        System.arraycopy(outData,0,iframeData,mPpsSps.length,outData.length);
                        outData = iframeData;
                    }*/
                    Util.save(outData,0,outData.length,path,true);
                    mMediaCodec.releaseOutputBuffer(outputBufferIndex,false);
                    outputBufferIndex = mMediaCodec.dequeueOutputBuffer(bufferInfo,0);
                }
            }else {
                Log.i("sportdream","No buffer available !");
            }
        }catch (Exception e){
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            String stack = sw.toString();
            Log.i("sportdream", stack);
            e.printStackTrace();
        }finally {
            mCamera.addCallbackBuffer(cameraBuffer);
        }
    }

    public synchronized void startPreview(){
        Log.i("sportdream","startPreview");
            mCamera.startPreview();
            int previewFormat = mCamera.getParameters().getPreviewFormat();
            Camera.Size previewSize = mCamera.getParameters().getPreviewSize();
            int size = previewSize.width*previewSize.height*ImageFormat.getBitsPerPixel(previewFormat)/8;
            mCamera.addCallbackBuffer(new byte[size]);
        if(previewCallback == null){
            Log.i("sportdream","previewCallback is null");
        }
            mCamera.setPreviewCallbackWithBuffer(previewCallback);
            //started = true;
            //btnSwitch.setText("停止");
    }

    public synchronized void stopPreview(){
        if(mCamera != null){
            mCamera.stopPreview();
            mCamera.setPreviewCallbackWithBuffer(null);
        }
    }

    protected synchronized void destroyCamera(){
        if(mCamera != null){
            mCamera.stopPreview();
            try{
                mCamera.release();
            }catch (Exception e){

            }
            mCamera = null;
        }
    }

    protected void stopMediaCodec(){
        mMediaCodec.stop();
        mMediaCodec.release();
        mMediaCodec = null;
    }

    public void onClick(View v){
                if(!this.startRecord){
                    this.startRecord = true;
                    btnSwitch.setText("停止");
                }else{
                    this.startRecord = false;
                    btnSwitch.setText("开始");
                }

    }

    @Override
    protected void onDestroy(){
        if(surfaceView != null){
            destroyCamera();
        }
        if(mMediaCodec != null){
            stopMediaCodec();
        }
        if(mCacheQueue != null){
            mCacheQueue.exit();
        }
        super.onDestroy();
    }
}

































