package com.sportdream.H264AACHWEncode;

import android.app.Activity;
import android.graphics.ImageFormat;
import android.hardware.Camera;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.os.Bundle;
import android.os.Environment;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.Toast;

import com.sportdream.R;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.ByteBuffer;
import java.util.Iterator;
import java.util.List;
import android.util.Log;

/**
 * Created by lili on 2017/10/8.
 */

@SuppressWarnings("deprecation")
public class RecordActivity extends Activity implements SurfaceHolder.Callback,View.OnClickListener {
    String path = Environment.getExternalStorageDirectory()+"/sportdream.h264";
    int width = 1280,height=720;
    int framerate,bitrate;
    int mCameraId = Camera.CameraInfo.CAMERA_FACING_BACK;
    MediaCodec mMediaCodec;
    SurfaceView surfaceView;
    SurfaceHolder surfaceHolder;
    Camera mCamera;
    NV21Convertor mConvertor;
    Button btnSwitch;
    boolean started = false;

    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
        ,WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.record_main);
        btnSwitch = (Button)findViewById(R.id.btn_switch);
        btnSwitch.setOnClickListener(this);
        initMediaCodec();
        surfaceView = (SurfaceView)findViewById(R.id.sv_surfaceview);
        surfaceView.getHolder().addCallback(this);
        surfaceView.getHolder().setFixedSize(getResources().getDisplayMetrics().widthPixels,
                getResources().getDisplayMetrics().heightPixels);
    }

    private void initMediaCodec(){
        int dgree = getDgree();
        framerate = 15;
        bitrate = 2*width*height*framerate/20;
        EncoderDebugger debugger = EncoderDebugger.debug(getApplicationContext(),width,height);
        mConvertor = debugger.getNV21Convertor();
        try{
            mMediaCodec = MediaCodec.createByCodecName(debugger.getEncoderName());
            MediaFormat mediaFormat;
            if(dgree == 0){
                mediaFormat = MediaFormat.createVideoFormat("video/avc",height,width);
            }else{
                mediaFormat = MediaFormat.createVideoFormat("video/avc",width,height);
            }
            mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE,bitrate);
            mediaFormat.setInteger(MediaFormat.KEY_FRAME_RATE,framerate);
            mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT,debugger.getEncoderColorFormat());
            mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL,1);
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

    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder){
        stopPreview();
        destroyCamera();
    }

    Camera.PreviewCallback previewCallback = new Camera.PreviewCallback(){
        byte[] mPpsSps = new byte[0];
        @Override
        public void onPreviewFrame(byte[] data,Camera camera){
            if(data == null){
                return;
            }
            ByteBuffer[] inputBuffers = mMediaCodec.getInputBuffers();
            ByteBuffer[] outputBuffers = mMediaCodec.getOutputBuffers();
            byte[] dst = new byte[data.length];
            Camera.Size previewSize = mCamera.getParameters().getPreviewSize();
            if(getDgree() == 0){
                dst = Util.rotateNV21Degree90(data,previewSize.width,previewSize.height);
            }else{
                dst = data;
            }
            try{
                int bufferIndex = mMediaCodec.dequeueInputBuffer(5000000);
                if(bufferIndex >= 0){
                    inputBuffers[bufferIndex].clear();
                    mConvertor.convert(dst,inputBuffers[bufferIndex]);
                    mMediaCodec.queueInputBuffer(bufferIndex,0,inputBuffers[bufferIndex].position()
                    ,System.nanoTime()/1000,0);
                    MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
                    int outputBufferIndex = mMediaCodec.dequeueOutputBuffer(bufferInfo,0);
                    while (outputBufferIndex>=0){
                        ByteBuffer outputBuffer = outputBuffers[outputBufferIndex];
                        byte[] outData = new byte[bufferInfo.size];
                        outputBuffer.get(outData);
                        //记录pps和sps
                        if(outData[0] ==0&&outData[1]==0&&outData[2]==0&&outData[3]==1&&outData[4]==103){
                            mPpsSps = outData;
                        }else if(outData[0] == 0 && outData[1] == 0 && outData[2] == 0 && outData[3] == 1 && outData[4] == 101){
                            //在关键帧前面加上pps和sps数据
                            byte[] iframeData = new byte[mPpsSps.length+outData.length];
                            System.arraycopy(mPpsSps,0,iframeData,0,mPpsSps.length);
                            System.arraycopy(outData,0,iframeData,mPpsSps.length,outData.length);
                            outData = iframeData;
                        }
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
                mCamera.addCallbackBuffer(dst);
            }
        }
    };

    public synchronized void startPreview(){
        if(mCamera != null && !started){
            mCamera.startPreview();
            int previewFormat = mCamera.getParameters().getPreviewFormat();
            Camera.Size previewSize = mCamera.getParameters().getPreviewSize();
            int size = previewSize.width*previewSize.height*ImageFormat.getBitsPerPixel(previewFormat)/8;
            mCamera.addCallbackBuffer(new byte[size]);
            mCamera.setPreviewCallbackWithBuffer(previewCallback);
            started = true;
            btnSwitch.setText("停止");
        }
    }

    public synchronized void stopPreview(){
        if(mCamera != null){
            mCamera.stopPreview();
            mCamera.setPreviewCallbackWithBuffer(null);
            started = false;
            btnSwitch.setText("开始");
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

    @Override
    public void onClick(View v){
        switch (v.getId()){
            case R.id.btn_switch:
                if(!started){
                    startPreview();
                }else{
                    stopPreview();
                }
                break;
        }
    }

    @Override
    protected void onDestroy(){
        super.onDestroy();
        destroyCamera();
        mMediaCodec.stop();
        mMediaCodec.release();
        mMediaCodec = null;
    }
}

































