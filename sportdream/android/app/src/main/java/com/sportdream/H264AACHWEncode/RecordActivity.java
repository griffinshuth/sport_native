package com.sportdream.H264AACHWEncode;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.ImageFormat;
import android.hardware.Camera;
import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.os.Bundle;
import android.os.Environment;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.sportdream.DreamSDK.FFmpegEncoder;
import com.sportdream.Listeners.LocalCameraSocketListener;
import com.sportdream.R;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.ByteBuffer;
import java.util.Iterator;
import java.util.List;
import android.util.Log;

import com.sportdream.nativec.YUVUtils;
import com.sportdream.network.h264CacheQueue;

@SuppressWarnings("deprecation")
public class RecordActivity extends Activity implements SurfaceHolder.Callback,LocalCameraSocketListener {

    String mDeviceID;
    int mRoomID;
    int CameraType;
    String CameraName;
    String highlightIP;

    String filename;
    String _h264BigFileName;
    String _h264SmallFileName;
    String _h264BigMetaFileName;
    String _h264SmallMetaFileName;
    String _h264BigFile_path;
    String _h264SmallFile_path;
    String _metaBigFile_path;
    String _metaSmallFile_path;

    int width = 1280,height=720;
    int mSmallWidth = width/4;
    int mSmallHeight = height/4;
    int framerate,bitrate;
    int mCameraId = Camera.CameraInfo.CAMERA_FACING_BACK;
    MediaCodec mBigMediaCodec;
    MediaCodec mSmallMediaCodec;
    SurfaceView surfaceView;
    TextView    mServerInfoView;
    Button      mDirectorButton;
    Button      mHighlightButton;

    Camera mCamera;
    EncoderDebugger debugger;
    NV21Convertor mConvertor;

    EncoderDebugger mSmallDebugger;
    NV21Convertor mSmallConvertor;

    FFmpegEncoder softSmallEncoder = new FFmpegEncoder();
    Boolean isSmallSpsPpsSend = false;
    FFmpegEncoder softBigEncoder = new FFmpegEncoder();
    Boolean isBigSpsPpsSend = false;

    Boolean isSoftEncode = false;   //默认是硬编码，如果硬编码有兼容性问题，则切换到软编码

    boolean startRecord = false;


    private h264CacheQueue mCacheQueue;
    private int framecount = 0;
    private long beginTimestamp = 0;

    private YUVUtils yuvUtils = new YUVUtils();
    private byte[] mYUVSmallBuffer = new byte[mSmallWidth*mSmallHeight*3/2];


    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);//横屏
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
        ,WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.record_main);

        mDeviceID = getIntent().getStringExtra("deviceID");
        mRoomID = getIntent().getIntExtra("roomID",0);
        CameraType = getIntent().getIntExtra("CameraType",0);
        CameraName = getIntent().getStringExtra("CameraName");
        highlightIP = getIntent().getStringExtra("highlightIP");


        if(getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE){
            //---landscape mode---
            mServerInfoView = (TextView)findViewById(R.id.server_connect_info);
            final Activity self = this;
            mDirectorButton = (Button)findViewById(R.id.DirectorButton);
            mDirectorButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mCacheQueue.connectDirectServer();
                }
            });
            mHighlightButton = (Button)findViewById(R.id.HighlightButton);
            mHighlightButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mCacheQueue.getHighlightServerIPAndConnect();
                }
            });
            surfaceView = (SurfaceView)findViewById(R.id.sv_surfaceview);
            surfaceView.getHolder().addCallback(this);
            surfaceView.getHolder().setFixedSize(getResources().getDisplayMetrics().widthPixels,
                    getResources().getDisplayMetrics().heightPixels);

            debugger = EncoderDebugger.debug(getApplicationContext(),width,height);
            mConvertor = debugger.getNV21Convertor();

            mSmallDebugger = EncoderDebugger.debug(getApplicationContext(),mSmallWidth,mSmallHeight);
            mSmallConvertor = mSmallDebugger.getNV21Convertor();

            filename = String.format("Camera_%d_%s_%s", mRoomID,mDeviceID,CameraName);
            _h264BigFileName = String.format("%s_big.h264",filename);
            _h264SmallFileName = String.format("%s_small.h264",filename);
            _h264BigMetaFileName = String.format("%s_big.meta",filename);
            _h264SmallMetaFileName = String.format("%s_small.meta",filename);
            _h264BigFile_path = getExternalFilesDir(null)+_h264BigFileName;
            _h264SmallFile_path = getExternalFilesDir(null)+_h264SmallFileName;
            _metaBigFile_path = getExternalFilesDir(null)+_h264BigMetaFileName;
            _metaSmallFile_path = getExternalFilesDir(null)+_h264SmallMetaFileName;
        }
    }

    @Override
    protected void onResume(){
        super.onResume();
        if(getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE){
            startBigMediaCodec();
            startSmallMediaCodec();
            //softBigEncoder.startEncoder(width,height,24,1200*1000);
            //softSmallEncoder.startEncoder(mSmallWidth,mSmallHeight,24,300*1000);
            mCacheQueue = new h264CacheQueue(mDeviceID,mRoomID,CameraType,CameraName,_h264BigFile_path,_h264SmallFile_path,_metaBigFile_path,_metaSmallFile_path,highlightIP);
            mCacheQueue.addResetListener(this);
            this.startRecord = true;
        }
    }

    @Override
    protected void onPause(){
        if(getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE){
            this.startRecord = false;
            if(mBigMediaCodec != null){
                stopBigMediaCodec();
            }
            if(mSmallMediaCodec != null){
                stopSmallMediaCodec();
            }
            if(mCacheQueue != null){
                mCacheQueue.exit();
            }
            //softBigEncoder.stopEncoder();
            //softSmallEncoder.stopEncoder();
        }
        super.onPause();
    }

    public void OnDirectServerConnected(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mDirectorButton.setText("导播服务器连接成功");
            }
        });
    }
    public void OnDirectServerDisconnected(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mDirectorButton.setText("导播服务器连接断开");
            }
        });
    }
    public void OnHighlightServerConnected(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mHighlightButton.setText("集锦服务器连接成功");
            }
        });
    }
    public void OnHighlightServerDisconnected(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mHighlightButton.setText("集锦服务器连接断开");
            }
        });
    }
    public void OnHighlightServerInfo(final String message){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(getBaseContext(),message,Toast.LENGTH_LONG).show();
            }
        });
    }
    public void OnMediaCodecReset(final boolean isBig){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                startRecord = false;
                /*if(isBig)
                    resetBigMediaCodec();
                else
                    resetSmallMediaCodec();*/
                //同时重置大小流编码器
                resetBigMediaCodec();
                resetSmallMediaCodec();
                startRecord = true;
            }
        });
    }

    private void startBigMediaCodec(){
        int dgree = getDgree();
        framerate = 20;
        bitrate = 1600*1000;

        try{
            mBigMediaCodec = MediaCodec.createEncoderByType("video/avc"); //MediaCodec.createByCodecName(debugger.getEncoderName());
            MediaFormat mediaFormat;
            if(dgree == 0){
                mediaFormat = MediaFormat.createVideoFormat("video/avc",height,width);
            }else{
                mediaFormat = MediaFormat.createVideoFormat("video/avc",width,height);
            }
            mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE,bitrate);
            mediaFormat.setInteger(MediaFormat.KEY_FRAME_RATE,framerate);
            //mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT,debugger.getEncoderColorFormat());
            mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible);
            mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL,1);
            mBigMediaCodec.configure(mediaFormat,null,null,MediaCodec.CONFIGURE_FLAG_ENCODE);
            mBigMediaCodec.start();
        }catch (IOException e){
            e.printStackTrace();
        }
    }

    protected void stopBigMediaCodec(){
        mBigMediaCodec.stop();
        mBigMediaCodec.release();
        mBigMediaCodec = null;
    }

    public void resetBigMediaCodec(){
        stopBigMediaCodec();
        startBigMediaCodec();
    }

    private void startSmallMediaCodec(){
        int dgree = getDgree();
        framerate = 20;
        bitrate = 300*1000;

        try{
            mSmallMediaCodec = MediaCodec.createEncoderByType("video/avc"); //MediaCodec.createByCodecName(debugger.getEncoderName());
            MediaFormat mediaFormat;
            if(dgree == 0){
                mediaFormat = MediaFormat.createVideoFormat("video/avc",mSmallHeight,mSmallWidth);
            }else{
                mediaFormat = MediaFormat.createVideoFormat("video/avc",mSmallWidth,mSmallHeight);
            }
            mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE,bitrate);
            mediaFormat.setInteger(MediaFormat.KEY_FRAME_RATE,framerate);
            //mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT,debugger.getEncoderColorFormat());
            mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible);
            mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL,1);
            mSmallMediaCodec.configure(mediaFormat,null,null,MediaCodec.CONFIGURE_FLAG_ENCODE);
            mSmallMediaCodec.start();
        }catch (IOException e){
            e.printStackTrace();
        }
    }

    private void stopSmallMediaCodec(){
        mSmallMediaCodec.stop();
        mSmallMediaCodec.release();
        mSmallMediaCodec = null;
    }

    public void resetSmallMediaCodec(){
        stopSmallMediaCodec();
        startSmallMediaCodec();
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

    private boolean createCamera(){
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
            //parameters.setPreviewFpsRange(max[0],max[1]);
            parameters.setPreviewFpsRange(20000,20000);
            // 4、设置视频记录的连续自动对焦模式
            if (parameters.getSupportedFocusModes().contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO)) {
                parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO);
            }
            //设置白平衡
            /*WHITE_BALANCE_AUTO WHITE_BALANCE_INCANDESCENT
                    WHITE_BALANCE_FLUORESCENT
                    WHITE_BALANCE_WARM_FLUORESCENT
                    WHITE_BALANCE_DAYLIGHT
                    WHITE_BALANCE_CLOUDY_DAYLIGHT
                    WHITE_BALANCE_TWILIGHT
                    WHITE_BALANCE_SHADE*/
            //parameters.setWhiteBalance(Camera.Parameters.WHITE_BALANCE_CLOUDY_DAYLIGHT);
            parameters.setVideoStabilization(true);
            parameters.getZoomRatios();
            mCamera.setParameters(parameters);
            //mCamera.autoFocus(null);
            int displayRotation;
            displayRotation = (cameraRotationOffset-getDgree()+360)%360;
            mCamera.setDisplayOrientation(displayRotation);
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

    public synchronized void startPreview(SurfaceHolder surfaceHolder){
        Log.i("sportdream","startPreview");
        try{
            createCamera();
            mCamera.setPreviewDisplay(surfaceHolder);
            mCamera.setPreviewCallback(previewCallback);
            mCamera.startPreview();
        }catch (IOException e){
            e.printStackTrace();
        }

    }

    public synchronized void stopPreview(){
        if(mCamera != null){
            mCamera.stopPreview();
            mCamera.setPreviewCallback(null);
            destroyCamera();
        }
    }

    protected synchronized void destroyCamera(){
        if(mCamera != null){
            try{
                mCamera.release();
            }catch (Exception e){

            }
            mCamera = null;
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder){
        startPreview(holder);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder,int format,int width,int height){

    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder){
        stopPreview();
    }

    public void softBigEncode(byte[] buffer){
        byte[] softData = softBigEncoder.encode(buffer);
        if(softData != null){
            if(softData[0] ==0&&softData[1]==0&&softData[2]==0&&softData[3]==1&&((softData[4]& 0x1F)==0x07)){
                Log.i("sportdream","sps");
                int spslen = 0;
                //寻找pps
                int ppsbeginindex = 0;
                int ppslength = 0;
                for(int i=5;i<softData.length-4;i++){
                    if(softData[i] ==0&&softData[i+1]==0&&softData[i+2]==0&&softData[i+3]==1&&((softData[i+4]& 0x1F)==0x08)){
                        spslen = i;
                        ppsbeginindex = i;
                        break;
                    }
                }
                //寻找I帧
                for(int i=ppsbeginindex+5;i<softData.length-4;i++){
                    if(softData[i] ==0&&softData[i+1]==0&&softData[i+2]==1&&((softData[i+3]& 0x1F)==0x05)){
                        Log.i("sportdream","iframe");
                        ppslength = i-spslen;
                        int iframeLength = softData.length - i;
                        //分离视频帧
                        byte[] sps = new byte[spslen-4];
                        System.arraycopy(softData,4,sps,0,spslen-4);
                        byte[] pps = new byte[ppslength-4];
                        System.arraycopy(softData,ppsbeginindex+4,pps,0,ppslength-4);
                        byte[] iframe = new byte[iframeLength-3];
                        System.arraycopy(softData,i+3,iframe,0,iframeLength-3);
                        if(!isBigSpsPpsSend){
                            mCacheQueue.setBigSPSPPS(pps,sps);
                            isBigSpsPpsSend = true;
                        }
                        mCacheQueue.enterBigH264(iframe,true);
                        break;
                    }
                }
            }else{
                Log.i("sportdream","PFrame");
                byte[] pframe = new byte[softData.length-4];
                System.arraycopy(softData,4,pframe,0,softData.length-4);
                mCacheQueue.enterBigH264(pframe,false);
            }
        }
    }

    public void softSmallEncode(byte[] buffer){
        byte[] softData = softSmallEncoder.encode(buffer);
        if(softData != null){
            if(softData[0] ==0&&softData[1]==0&&softData[2]==0&&softData[3]==1&&((softData[4]& 0x1F)==0x07)){
                Log.i("sportdream","sps");
                int spslen = 0;
                //寻找pps
                int ppsbeginindex = 0;
                int ppslength = 0;
                for(int i=5;i<softData.length-4;i++){
                    if(softData[i] ==0&&softData[i+1]==0&&softData[i+2]==0&&softData[i+3]==1&&((softData[i+4]& 0x1F)==0x08)){
                        spslen = i;
                        ppsbeginindex = i;
                        break;
                    }
                }
                //寻找I帧
                for(int i=ppsbeginindex+5;i<softData.length-4;i++){
                    if(softData[i] ==0&&softData[i+1]==0&&softData[i+2]==1&&((softData[i+3]& 0x1F)==0x05)){
                        Log.i("sportdream","iframe");
                        ppslength = i-spslen;
                        int iframeLength = softData.length - i;
                        //分离视频帧
                        byte[] sps = new byte[spslen-4];
                        System.arraycopy(softData,4,sps,0,spslen-4);
                        byte[] pps = new byte[ppslength-4];
                        System.arraycopy(softData,ppsbeginindex+4,pps,0,ppslength-4);
                        byte[] iframe = new byte[iframeLength-3];
                        System.arraycopy(softData,i+3,iframe,0,iframeLength-3);
                        if(!isSmallSpsPpsSend){
                            mCacheQueue.setSmallSPSPPS(pps,sps);
                            isSmallSpsPpsSend = true;
                        }
                        mCacheQueue.enterSmallH264(iframe,true);
                        break;
                    }
                }
            }else{
                Log.i("sportdream","PFrame");
                byte[] pframe = new byte[softData.length-4];
                System.arraycopy(softData,4,pframe,0,softData.length-4);
                mCacheQueue.enterSmallH264(pframe,false);
            }
        }
    }

    Camera.PreviewCallback previewCallback = new Camera.PreviewCallback(){
        @Override
        public void onPreviewFrame(byte[] data,Camera camera){
            if(beginTimestamp == 0){
                beginTimestamp = System.currentTimeMillis();
            }
            long currentTimestamp = System.currentTimeMillis();
            framecount++;
            double averageInterval = (currentTimestamp-beginTimestamp)/framecount;
            int fps = 0;
            if(averageInterval>0){
                fps = (int)(1000/averageInterval);
            }
            mServerInfoView.setText("数量："+framecount+",帧率："+fps);
            yuvUtils.NV21Scale(width,height,data,mSmallWidth,mSmallHeight,mYUVSmallBuffer);
            if(!isSoftEncode){
                encodeBigH264(data);
                encodeSmallH264(mYUVSmallBuffer);
            }else{
                softBigEncode(data);
                softSmallEncode(mYUVSmallBuffer);
            }
        }
    };

    private void encodeBigH264(byte[] bigdata){
        if(!this.startRecord){
            //mCamera.addCallbackBuffer(cameraBuffer);
            return;
        }
        byte[] mPpsSps = new byte[0];
        byte[] buffer;
        ByteBuffer[] inputBuffers = mBigMediaCodec.getInputBuffers();
        ByteBuffer[] outputBuffers = mBigMediaCodec.getOutputBuffers();
        Camera.Size previewSize = mCamera.getParameters().getPreviewSize();
        if(getDgree() == 0){
            buffer = Util.rotateNV21Degree90(bigdata,previewSize.width,previewSize.height);
        }else{
            buffer = bigdata;
        }
        try{
            int bufferIndex = mBigMediaCodec.dequeueInputBuffer(5000000);
            if(bufferIndex >= 0){
                inputBuffers[bufferIndex].clear();
                mConvertor.convert(buffer,inputBuffers[bufferIndex]);
                mBigMediaCodec.queueInputBuffer(bufferIndex,0,inputBuffers[bufferIndex].position()
                        ,System.nanoTime()/1000,0);
                MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
                int outputBufferIndex = mBigMediaCodec.dequeueOutputBuffer(bufferInfo,0);
                while (outputBufferIndex>=0){
                    ByteBuffer outputBuffer = outputBuffers[outputBufferIndex];
                    byte[] outData = new byte[bufferInfo.size];
                    //Log.i("sportdream","frame length:"+bufferInfo.size);
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
                                mCacheQueue.setBigSPSPPS(pps,sps);
                                break;
                            }
                        }
                    }else{
                        boolean isKeyframe = false;
                        int type = (outData[4]& 0x1F);
                        //Log.w("sportdream","nalu type:"+type);
                        if(outData[0] == 0 && outData[1] == 0 && outData[2] == 0 && outData[3] == 1 && ((outData[4]& 0x1F)==0x05)){
                            isKeyframe = true;
                        }
                        byte[] dataWithHeader = new byte[outData.length-4];
                        System.arraycopy(outData,4,dataWithHeader,0,outData.length-4);

                        mCacheQueue.enterBigH264(dataWithHeader,isKeyframe);
                    }

                    mBigMediaCodec.releaseOutputBuffer(outputBufferIndex,false);
                    outputBufferIndex = mBigMediaCodec.dequeueOutputBuffer(bufferInfo,0);
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
            //mCamera.addCallbackBuffer(cameraBuffer);
        }
    }

    private void encodeSmallH264(byte[] smalldata){
        if(!this.startRecord){
            return;
        }
        byte[] mPpsSps = new byte[0];
        byte[] buffer;
        ByteBuffer[] inputBuffers = mSmallMediaCodec.getInputBuffers();
        ByteBuffer[] outputBuffers = mSmallMediaCodec.getOutputBuffers();
        if(getDgree() == 0){
            buffer = Util.rotateNV21Degree90(smalldata,mSmallWidth,mSmallHeight);
        }else{
            buffer = smalldata;
        }

        try{
            int bufferIndex = mSmallMediaCodec.dequeueInputBuffer(5000000);
            if(bufferIndex >= 0){
                inputBuffers[bufferIndex].clear();
                mSmallConvertor.convert(buffer,inputBuffers[bufferIndex]);
                mSmallMediaCodec.queueInputBuffer(bufferIndex,0,inputBuffers[bufferIndex].position()
                        ,System.nanoTime()/1000,0);
                MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
                int outputBufferIndex = mSmallMediaCodec.dequeueOutputBuffer(bufferInfo,0);
                while (outputBufferIndex>=0){
                    ByteBuffer outputBuffer = outputBuffers[outputBufferIndex];
                    byte[] outData = new byte[bufferInfo.size];
                    outputBuffer.get(outData);

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
                                mCacheQueue.setSmallSPSPPS(pps,sps);
                                mCacheQueue.setSPSPPSToHighlightServer(pps,sps);
                                break;
                            }
                        }
                    }else{
                        boolean isKeyframe = false;
                        int type = (outData[4]& 0x1F);
                        if(outData[0] == 0 && outData[1] == 0 && outData[2] == 0 && outData[3] == 1 && ((outData[4]& 0x1F)==0x05)){
                            isKeyframe = true;
                        }
                        byte[] dataWithHeader = new byte[outData.length-4];
                        System.arraycopy(outData,4,dataWithHeader,0,outData.length-4);

                        mCacheQueue.enterSmallH264(dataWithHeader,isKeyframe);
                        mCacheQueue.enterH264DataToHighlightServer(dataWithHeader,isKeyframe);
                    }

                    mSmallMediaCodec.releaseOutputBuffer(outputBufferIndex,false);
                    outputBufferIndex = mSmallMediaCodec.dequeueOutputBuffer(bufferInfo,0);
                }
            }else{
                Log.i("sportdream","No buffer available !");
            }
        }catch (Exception e){
            e.printStackTrace();
        }finally {

        }
    }

}

































