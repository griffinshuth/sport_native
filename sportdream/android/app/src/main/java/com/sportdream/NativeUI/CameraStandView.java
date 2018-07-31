package com.sportdream.NativeUI;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.hardware.camera2.CameraMetadata;
import android.os.Environment;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.sportdream.Activity.VideoDecoderThread;
import com.sportdream.DreamSDK.FFmpegDecoder;
import com.sportdream.DreamSDK.MediaCodecDecoder;

/**
 * Created by lili on 2018/5/4.
 */

public class CameraStandView extends SurfaceView implements SurfaceHolder.Callback {
    private MediaCodecDecoder mDecoders;
    private FFmpegDecoder mSoftDecoders;
    private int mWidth = 320;
    private int mHeight = 180;
    private String mDeviceID;
    private Boolean mIsHighlight;

    public CameraStandView(Context context){
        super(context);
        this.getHolder().addCallback(this);
        mDecoders = new MediaCodecDecoder(mWidth,mHeight);
        mSoftDecoders = new FFmpegDecoder();
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {

    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width,int height) {
        //mDecoders.setSurface(holder.getSurface());
        int videoWidth = mWidth;
        int videoHeight = mHeight;
        Bitmap rawBitmap = Bitmap.createBitmap(videoWidth,videoHeight, Bitmap.Config.ARGB_8888);
        Paint p = new Paint();
        p.setColor(Color.RED);
        p.setTextSize(16);
        p.setAntiAlias(true);
        Canvas canvasTemp = new Canvas(rawBitmap);
        canvasTemp.drawColor(Color.BLUE);
        canvasTemp.drawText("勇士",50,18,p);
        canvasTemp.drawText("火箭",50,48,p);
        p.setTextSize(12);
        canvasTemp.drawText("120",127,17,p);
        canvasTemp.drawText("110",127,45,p);
        p.setTextSize(10);
        canvasTemp.drawText("第一节",152,18,p);
        p.setTextSize(9);
        canvasTemp.drawText("12:00",145,32,p);
        p.setTextSize(10);
        canvasTemp.drawText("24",152,47,p);
        canvasTemp.save();

        int[] argb = new int[videoWidth * videoHeight];
        rawBitmap.getPixels(argb,0,videoWidth,0,0,videoWidth,videoHeight);
        byte[] buffer = new byte[videoWidth*videoHeight*4];
        int index = 0;
        for(int i=0;i<argb.length;i++){
            int A = (argb[i] & 0xff000000) >> 24; // a is not used obviously
            int R = (argb[i] & 0xff0000) >> 16;
            int G = (argb[i] & 0xff00) >> 8;
            int B = (argb[i] & 0xff) >> 0;
            buffer[index] = (byte)A;
            buffer[index+1] = (byte)R;
            buffer[index+2] = (byte)G;
            buffer[index+3] = (byte)B;
            index += 4;
        }

        mSoftDecoders.start(holder.getSurface(),width,height,videoWidth,videoHeight,buffer);
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        mSoftDecoders.stop();
    }

    public void H264Decode(byte[] data,int length){
        //mDecoders.frameProcess(data,length);
        mSoftDecoders.DecodeFrame(data);
    }

    public void setDeviceID(String deviceID){
        mDeviceID = deviceID;
    }

    public void setIsHighlight(Boolean isHighlight){
        mIsHighlight = isHighlight;
    }
}
