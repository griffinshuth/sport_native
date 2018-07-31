package com.sportdream.NativeUI;

import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

/**
 * Created by lili on 2018/5/3.
 */

public class HighlightsViewManager  extends SimpleViewManager<SurfaceView> {
    private ThemedReactContext mReactContext;

    public String getName(){
        return "HighlightsView";
    }

    public SurfaceView createViewInstance(ThemedReactContext context){
        mReactContext = context;
        SurfaceView view = new SurfaceView(context);
        return view;
    }

    @ReactProp(name = "PlayerStart")
    public void setPlayerStart(SurfaceView view, Boolean isStart) {

    }
}
