package com.sportdream.NativeModule;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.annotation.Nullable;
import android.util.Log;

import com.baidu.location.c.a;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.JSApplicationIllegalArgumentException;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.hyphenate.chat.EMMessage;
import com.hyphenate.easeui.EaseConstant;
import com.qiniu.android.http.ResponseInfo;
import com.qiniu.android.storage.UpCompletionHandler;
import com.qiniu.android.storage.UpProgressHandler;
import com.qiniu.android.storage.UploadManager;
import com.qiniu.android.storage.UploadOptions;
import com.qiniu.android.utils.StringUtils;

import org.apache.http.protocol.HTTP;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.io.File;

/**
 * Created by lili on 2017/9/26.
 */

public class QiniuModule extends ReactContextBaseJavaModule {
    private ReactApplicationContext context;
    public QiniuModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
    }
    @Override
    public String getName(){
        return "QiniuModule";
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    private String getImagePath(Uri uri, String selection) {
        String path = null;
        Cursor cursor = context.getContentResolver().query(uri, null, selection, null, null);
        if (cursor != null) {
            if (cursor.moveToFirst()) {
                path = cursor.getString(cursor.getColumnIndex(MediaStore.Images.Media.DATA));
            }

            cursor.close();
        }
        return path;
    }

    @ReactMethod
    public void upload(final String filepath,final String uploadTokenUrl, final Promise promise){

        new Thread(){
            @Override
            public void run(){
                //获得token
                String token = null;
                byte[] b = null;
                try {
                    URL url = new URL(uploadTokenUrl);
                    URLConnection conn = url.openConnection();
                    HttpURLConnection httpconn = (HttpURLConnection)conn;
                    httpconn.setConnectTimeout(6000);
                    int responseCode = httpconn.getResponseCode();
                    if(responseCode == HttpURLConnection.HTTP_OK){
                        InputStream in = httpconn.getInputStream();
                        BufferedReader reader = new BufferedReader(new InputStreamReader(in));
                        String line = null;
                        while ((line = reader.readLine()) != null){
                            if(token == null){
                                token = line;
                            }else{
                                token += line;
                            }
                        }
                        reader.close();
                        in.close();
                        httpconn.disconnect();
                        Log.i("qiniu","token:"+token);

                    }
                }catch (MalformedURLException e){

                }catch (IOException e){

                }

                try{
                    File file = new File(filepath);
                    FileInputStream is = new FileInputStream(file);
                    b = new byte[is.available()];
                    is.read(b);
                }catch (FileNotFoundException e){
                    Log.i("qiniu","file not found");
                }catch (IOException e){

                }

               String localpath =  Environment.getExternalStorageDirectory().getPath();

                Log.i("qiniu","localfilepath:"+localpath);

                UploadManager uploadManager = new UploadManager();
                Log.i("qiniu", "filepath:"+filepath);

                uploadManager.put(filepath,null,token,new UpCompletionHandler() {
                    @Override
                    public void complete(String key, ResponseInfo info, JSONObject res) {
                        //res包含hash、key等信息，具体字段取决于上传策略的设置
                        if(info.isOK()) {
                            Log.i("qiniu", "Upload Success");
                        } else {
                            Log.i("qiniu", "Upload Fail");
                            //如果失败，这里可以把info信息上报自己的服务器，便于后面分析上传错误原因
                        }
                        Log.i("qiniu", key + ",\r\n " + info + ",\r\n " + res);
                        WritableMap map = Arguments.createMap();
                        try {
                            map.putString("name",res.getString("key"));
                            promise.resolve(map);
                        }catch (Exception e){

                        }


                    }
                },new UploadOptions(null, null, false,
                        new UpProgressHandler(){
                            public void progress(String key, double percent){
                                Log.i("qiniu", key + ": " + percent);
                                WritableMap params = Arguments.createMap();
                                params.putDouble("percent",percent);
                                sendEvent("uploadProgress", params);
                            }
                        }, null));
            }
        }.start();
    }

    @ReactMethod
    public void getFilePathByAssetsPath(String path,int width,int height,final Promise promise)
    {
        Uri url = Uri.parse(path);
        String filpath = getImagePath(url,null);
        //压缩图片，保存到临时文件
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        Bitmap bitmap = BitmapFactory.decodeFile(filpath, options);// 此时返回bm为空
        options.inJustDecodeBounds = false;
        int w = options.outWidth;
        int h = options.outHeight;
        options.inSampleSize = 2;
        bitmap = BitmapFactory.decodeFile(filpath, options);
        String savePath = context.getApplicationContext().getFilesDir()
                .getAbsolutePath()
                + "/cache/uploadimage/";
        File filePic;
        try {
            filePic = new File(savePath +  "Cacheuploadimage.jpg");
            if (!filePic.exists()) {
                filePic.getParentFile().mkdirs();
                filePic.createNewFile();
            }
            FileOutputStream fos = new FileOutputStream(filePic);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 50, fos);
            fos.flush();
            fos.close();

            String pathresult = filePic.getAbsolutePath();
            WritableMap map = Arguments.createMap();
            map.putString("FilePath",pathresult);
            promise.resolve(map);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    @ReactMethod
    public void h264Record(String deviceID,int CameraType,String CameraName,int roomID,String highlightIP){
        Activity currentActivity = getCurrentActivity();
        try{
            Class recordActivity = Class.forName("com.sportdream.H264AACHWEncode.RecordActivity");
            //Class recordActivity = Class.forName("com.sportdream.Activity.H264PlayerActivity");
            Intent intent = new Intent(currentActivity,recordActivity);
            intent.putExtra("deviceID", deviceID);
            intent.putExtra("CameraType", CameraType);
            intent.putExtra("CameraName",CameraName);
            intent.putExtra("roomID",roomID);
            intent.putExtra("highlightIP",highlightIP);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }
    }

    @ReactMethod
    public void agoraRemoteCamera(String AgoraChannelName){
        Activity currentActivity = getCurrentActivity();
        try{
            Class recordActivity = Class.forName("com.sportdream.Activity.AgoraRemoteCamera");
            Intent intent = new Intent(currentActivity,recordActivity);
            intent.putExtra("AgoraChannelName",AgoraChannelName);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }
    }

    @ReactMethod
    public void liveCommentorsActivity(String deviceID,int CameraType,String CameraName,int roomID){
        Activity currentActivity = getCurrentActivity();
        try{
            Class recordActivity = Class.forName("com.sportdream.H264AACHWEncode.AudioRecordActivity");
            Intent intent = new Intent(currentActivity,recordActivity);
            intent.putExtra("deviceID", deviceID);
            intent.putExtra("CameraType", CameraType);
            intent.putExtra("CameraName",CameraName);
            intent.putExtra("roomID",roomID);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }
    }
}
