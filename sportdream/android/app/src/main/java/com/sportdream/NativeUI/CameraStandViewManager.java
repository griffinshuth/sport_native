package com.sportdream.NativeUI;

import android.os.Environment;
import android.support.annotation.Nullable;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.sportdream.Activity.VideoDecoderThread;
import com.sportdream.DreamSDK.HighlightsServerCore;

/**
 * Created by lili on 2018/5/2.
 */

public class CameraStandViewManager extends SimpleViewManager<CameraStandView> {
    private ThemedReactContext mReactContext;
    public String getName(){
        return "CameraStandView";
    }

    public CameraStandView createViewInstance(ThemedReactContext context){
        mReactContext = context;
        CameraStandView view = new CameraStandView(context);
        return view;
    }

    @ReactProp(name = "DeviceID")
    public void setDeviceID(CameraStandView view, String deviceID) {
        if(deviceID != ""){
            HighlightsServerCore.getInstance().setCameraStandView(deviceID,view);
        }
    }

    @ReactProp(name = "IsHighlight")
    public void setIsHighlight(CameraStandView view,Boolean isHighlight){
        if(isHighlight){
            HighlightsServerCore.getInstance().setHighlightsView(view);
        }
    }
}
