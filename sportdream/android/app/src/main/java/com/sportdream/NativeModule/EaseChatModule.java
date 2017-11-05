package com.sportdream.NativeModule;

import android.content.Intent;

import com.facebook.react.bridge.JSApplicationIllegalArgumentException;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.hyphenate.EMCallBack;
import com.hyphenate.chat.EMClient;
import com.hyphenate.chat.EMMessage;
import com.hyphenate.easeui.EaseConstant;
import com.hyphenate.exceptions.HyphenateException;

import android.app.Activity;

/**
 * Created by lili on 2017/9/14.
 */

public class EaseChatModule extends ReactContextBaseJavaModule {
    public EaseChatModule(ReactApplicationContext reactContext){
        super(reactContext);
    }
    @Override
    public String getName(){
        return "ChatModule";
    }



    @ReactMethod
    public void login(String username, String password, final Promise promise){
        EMClient.getInstance().login(username, password, new EMCallBack() {
            @Override
            public void onSuccess() {
                promise.resolve("msg");
            }

            @Override
            public void onError(int i, String s) {
                promise.reject(s);
            }

            @Override
            public void onProgress(int i, String s) {

            }
        });
    }

    @ReactMethod
    public void chatWithFriends(String username){
        Activity currentActivity = getCurrentActivity();
        try{
            Class chatActivity = Class.forName("com.sportdream.ChatActivity");
            Intent intent = new Intent(currentActivity,chatActivity);
            intent.putExtra(EaseConstant.EXTRA_USER_ID,username);
            intent.putExtra(EaseConstant.EXTRA_CHAT_TYPE, EMMessage.ChatType.Chat);
            currentActivity.startActivity(intent);
        }catch (Exception e){
            throw new JSApplicationIllegalArgumentException(
                    "无法打开activity页面: "+e.getMessage());
        }


    }

    @ReactMethod
    public void logout(final Promise promise){
        EMClient.getInstance().logout(false, new EMCallBack() {
            @Override
            public void onSuccess() {
                promise.resolve("success");
            }

            @Override
            public void onError(int i, String s) {
                promise.reject("s");
            }

            @Override
            public void onProgress(int i, String s) {

            }
        });
    }

    @ReactMethod
    public void register(final String username, final String password, String nickname, final Promise promise){
        new Thread(new Runnable() {
            @Override
            public void run() {
                try{
                    EMClient.getInstance().createAccount(username,password);
                    promise.resolve("success");
                }catch (HyphenateException e){
                    e.printStackTrace();
                    promise.reject(e.getMessage());
                }

            }
        }).start();
    }
}
