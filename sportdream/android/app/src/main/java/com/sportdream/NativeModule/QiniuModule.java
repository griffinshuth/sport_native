package com.sportdream.NativeModule;

import android.app.Activity;
import android.content.Intent;
import android.os.Environment;
import android.util.Log;

import com.baidu.location.c.a;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.JSApplicationIllegalArgumentException;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.hyphenate.chat.EMMessage;
import com.hyphenate.easeui.EaseConstant;
import com.qiniu.android.http.ResponseInfo;
import com.qiniu.android.storage.UpCompletionHandler;
import com.qiniu.android.storage.UpProgressHandler;
import com.qiniu.android.storage.UploadManager;
import com.qiniu.android.storage.UploadOptions;

import org.apache.http.protocol.HTTP;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
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
    public QiniuModule(ReactApplicationContext reactContext){
        super(reactContext);
    }
    @Override
    public String getName(){
        return "QiniuModule";
    }

    @ReactMethod
    public void upload(final String filepath, final Promise promise){

        new Thread(){
            @Override
            public void run(){
                //获得token
                String token = null;
                byte[] b = null;
                try {
                    URL url = new URL("http://192.168.0.104/getUploadToken?bucket=grassroot");
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
                            }
                        }, null));
            }
        }.start();
    }

    @ReactMethod
    public void h264Record(){
        Activity currentActivity = getCurrentActivity();
        try{
            Class recordActivity = Class.forName("com.sportdream.H264AACHWEncode.RecordActivity");
            Intent intent = new Intent(currentActivity,recordActivity);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }
    }

    @ReactMethod
    public void agoraRemoteCamera(){
        Activity currentActivity = getCurrentActivity();
        try{
            Class recordActivity = Class.forName("com.sportdream.Activity.AgoraRemoteCamera");
            Intent intent = new Intent(currentActivity,recordActivity);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }
    }

    @ReactMethod
    public void liveCommentorsActivity(){
        Activity currentActivity = getCurrentActivity();
        try{
            Class recordActivity = Class.forName("com.sportdream.H264AACHWEncode.AudioRecordActivity");
            Intent intent = new Intent(currentActivity,recordActivity);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }
    }
}
