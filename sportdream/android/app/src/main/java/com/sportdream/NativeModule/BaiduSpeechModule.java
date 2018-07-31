package com.sportdream.NativeModule;

/**
 * Created by lili on 2018/2/28.
 */
import android.media.AudioManager;
import android.os.Bundle;
import android.support.annotation.Nullable;

import com.baidu.speech.EventListener;
import com.baidu.speech.EventManager;
import com.baidu.speech.EventManagerFactory;
import com.baidu.speech.asr.SpeechConstant;
import com.baidu.tts.client.SpeechSynthesizer;
import com.baidu.tts.client.TtsMode;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.LinkedHashMap;
import java.util.Map;

public class BaiduSpeechModule extends ReactContextBaseJavaModule implements EventListener {
    protected ReactApplicationContext context;
    private EventManager asr;
    private boolean enableOffline = false;
    //语音合成
    protected String appId = "10863068";
    protected String appKey = "g4DHPjiqRdqmzoZZsF2PxHct";
    protected String secretKey = "3xaV0kkxzv0WqQMKaweuQau7QEKDpGol";
    private TtsMode ttsMode = TtsMode.ONLINE;
    protected SpeechSynthesizer mSpeechSynthesizer;

    public BaiduSpeechModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
    }

    @Override
    public String getName(){
        return "BaiduASRModule";
    }

    protected void sendEvent(String eventName, @Nullable WritableMap params){
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName,params);
    }

    @ReactMethod
    public void init(){
        asr = EventManagerFactory.create(context,"asr");
        asr.registerListener(this);
        if(enableOffline){
            loadOfflineEngine();
        }
        start();
    }

    @ReactMethod
    public void destroy(){
        stop();
        asr.send(SpeechConstant.ASR_CANCEL,"{}",null,0,0);
        if(enableOffline){
            unloadOfflineEngine();
        }
        asr.unregisterListener(this);
        asr = null;
    }

    @ReactMethod
    public void initTTS(){
        mSpeechSynthesizer = SpeechSynthesizer.getInstance();
        mSpeechSynthesizer.setContext(context);
        int result = mSpeechSynthesizer.setAppId(appId);
        result = mSpeechSynthesizer.setApiKey(appKey, secretKey);
        mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_SPEAKER, "0");
        // 设置合成的音量，0-9 ，默认 5
        mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_VOLUME, "9");
        // 设置合成的语速，0-9 ，默认 5
        mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_SPEED, "5");
        // 设置合成的语调，0-9 ，默认 5
        mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_PITCH, "5");
        mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_MIX_MODE, SpeechSynthesizer.MIX_MODE_DEFAULT);
        mSpeechSynthesizer.setAudioStreamType(AudioManager.MODE_IN_CALL);
        result = mSpeechSynthesizer.initTts(ttsMode);
    }

    @ReactMethod
    public void speak(String text){
        mSpeechSynthesizer.speak(text);
    }

    @ReactMethod
    public void destroyTTS(){
        if (mSpeechSynthesizer != null) {
            mSpeechSynthesizer.stop();
            mSpeechSynthesizer.release();
            mSpeechSynthesizer = null;
        }
    }

    @Override
    public void onEvent(String name, String params, byte[] data, int offset, int length) {
        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_PARTIAL)) {
            //识别结果
            try{
                JSONObject json = new JSONObject(params);
                JSONArray arr = json.optJSONArray("results_recognition");
                String result = arr.getString(0);
                if(!result.equals(" ")){
                    WritableMap jsParams = Arguments.createMap();
                    jsParams.putString("RecognizeResult",result);
                    sendEvent("onVoiceRecognize",jsParams);
                }
            }catch (JSONException e){
                e.printStackTrace();
            }
        }else if(name.equals(SpeechConstant.CALLBACK_EVENT_ASR_READY)){
            //引擎初始化就绪
            WritableMap jsParams = Arguments.createMap();
            sendEvent("onRecognizeInit",jsParams);
        }else if(name.equals(SpeechConstant.CALLBACK_EVENT_ASR_BEGIN)){
            //检测到说话开始
            WritableMap jsParams = Arguments.createMap();
            sendEvent("onRecognizeBegin",jsParams);
        }else if(name.equals(SpeechConstant.CALLBACK_EVENT_ASR_END)){
            //检测到说话结束
            WritableMap jsParams = Arguments.createMap();
            sendEvent("onRecognizeEnd",jsParams);
        }else if(name.equals(SpeechConstant.CALLBACK_EVENT_ASR_EXIT)){
            start();
        }
    }

    private void start(){
        Map<String, Object> params = new LinkedHashMap<String, Object>();
        String event = null;
        event = SpeechConstant.ASR_START;
        if(enableOffline){
            params.put(SpeechConstant.DECODER,2);
        }
        params.put(SpeechConstant.ACCEPT_AUDIO_VOLUME,false);
        params.put(SpeechConstant.VAD_ENDPOINT_TIMEOUT,800);
        String json = null;
        json = new JSONObject(params).toString();
        asr.send(event,json,null,0,0);
    }

    private void stop(){
        asr.send(SpeechConstant.ASR_STOP,null,null,0,0);
    }

    private void loadOfflineEngine(){
        Map<String, Object> params = new LinkedHashMap<String, Object>();
        params.put(SpeechConstant.DECODER,2);
        params.put(SpeechConstant.ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH,"assets://baidu_speech_grammar.bsg");
        asr.send(SpeechConstant.ASR_KWS_LOAD_ENGINE,new JSONObject(params).toString(),null,0,0);
    }

    private void unloadOfflineEngine(){
        asr.send(SpeechConstant.ASR_KWS_UNLOAD_ENGINE,null,null,0,0);
    }


}
