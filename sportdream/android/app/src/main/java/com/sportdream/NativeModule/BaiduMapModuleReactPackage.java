package com.sportdream.NativeModule;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.sportdream.NativeUI.BaiduMapViewManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Created by lili on 2017/9/19.
 */

public class BaiduMapModuleReactPackage implements ReactPackage {
    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext){
        return Arrays.<ViewManager>asList(
                new BaiduMapViewManager()
        );
    }

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext  reactContext){
        List<NativeModule> modules = new ArrayList<>();
        modules.add(new BaiduMapModule(reactContext));
        return modules;
    }

    @Override
    public List<Class<? extends JavaScriptModule>> createJSModules(){
        return Collections.emptyList();
    }
}
