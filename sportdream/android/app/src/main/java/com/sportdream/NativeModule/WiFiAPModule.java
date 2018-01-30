package com.sportdream.NativeModule;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.provider.Settings;
import android.widget.Toast;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.Locale;

/**
 * Created by lili on 2017/11/14.
 */

public class WiFiAPModule extends ReactContextBaseJavaModule {
    public WiFiAPModule(ReactApplicationContext reactContext){
        super(reactContext);
        context = reactContext;
        wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
    }
    protected ReactApplicationContext context;
    WifiManager wifiManager;
    @Override
    public String getName(){
        return "WiFiAPModule";
    }

    private boolean isHasPermissions(){
        boolean result = false;
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M){
            Activity currentActivity = getCurrentActivity();
            if(!Settings.System.canWrite(getCurrentActivity())){
                Toast.makeText(getCurrentActivity(), "打开热点需要启用“修改系统设置”权限，请手动开启", Toast.LENGTH_SHORT).show();
                //清单文件中需要android.permission.WRITE_SETTINGS，否则打开的设置页面开关是灰色的
                Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
                intent.setData(Uri.parse("package:" + getCurrentActivity().getPackageName()));
                //判断系统能否处理，部分ROM无此action，如魅族Flyme
                if (intent.resolveActivity(context.getPackageManager()) != null) {
                    currentActivity.startActivity(intent);
                } else {
                    //打开应用详情页
                    intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                    intent.setData(Uri.parse("package:" + getCurrentActivity().getPackageName()));
                    if (intent.resolveActivity(context.getPackageManager()) != null) {
                        currentActivity.startActivity(intent);
                    }
                }
            }else{
                result = true;
            }
        }else{
            result = true;
        }
        return result;
    }

    /**
     * 打开网络共享与热点设置页面
     */
    private void openAPUI() {
        Intent intent = new Intent();
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        ComponentName comp = new ComponentName("com.android.settings", "com.android.settings.Settings$TetherSettingsActivity");
        intent.setComponent(comp);
        getCurrentActivity().startActivity(intent);
    }

    /**
     * 判断是否已打开WiFi热点
     *
     * @return
     */
    private boolean isWifiApEnabled() {
        boolean isOpen = false;
        try {
            Method method = wifiManager.getClass().getMethod("isWifiApEnabled");
            isOpen = (boolean) method.invoke(wifiManager);
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
        return isOpen;
    }


    @ReactMethod
    public void createCustomWifiAp(String name,String password){
        boolean result = false;
        //wifi和热点不能同时打开，所以打开热点的时候需要关闭wifi
        if(wifiManager.isWifiEnabled()){
            wifiManager.setWifiEnabled(false);
        }

        try{
            //热点的配置类
            WifiConfiguration apConfig = new WifiConfiguration();
            //配置热点的名称
            apConfig.SSID = "sport:"+ name;
            //配置热点的密码，至少八位
            apConfig.preSharedKey = password;
            //必须指定allowedKeyManagement，否则会显示为无密码
            //指定安全性为WPA_PSK，在不支持WPA_PSK的手机上看不到密码
            //apConfig.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK);
            //指定安全性为WPA2_PSK，（官方值为4，小米为6，如果指定为4，小米会变为无密码热点）
            int indexOfWPA2_PSK = 4;
            //从WifiConfiguration.KeyMgmt数组中查找WPA2_PSK的值
            for (int i = 0; i < WifiConfiguration.KeyMgmt.strings.length; i++) {
                if (WifiConfiguration.KeyMgmt.strings[i].equals("WPA2_PSK")) {
                    indexOfWPA2_PSK = i;
                    break;
                }
            }
            apConfig.allowedKeyManagement.set(indexOfWPA2_PSK);
            //通过反射调用设置热点
            Method method = wifiManager.getClass().getMethod("setWifiApEnabled", WifiConfiguration.class, boolean.class);
            //返回热点打开状态
            result = (Boolean) method.invoke(wifiManager, apConfig, true);
            if (!result) {
                Toast.makeText(getCurrentActivity(), "热点创建失败，请手动创建！", Toast.LENGTH_SHORT).show();
                openAPUI();
            }
        }catch (Exception e) {
            Toast.makeText(getCurrentActivity(), "热点创建失败，请手动创建！", Toast.LENGTH_SHORT).show();
            openAPUI();
        }
    }

    @ReactMethod
    public void switchWifiApEnabled(boolean enabled){
        boolean result = false;
        if(enabled){
            //wifi和热点不能同时打开，所以打开热点的时候需要关闭wifi
            if (wifiManager.isWifiEnabled()) {
                wifiManager.setWifiEnabled(false);
            }
        }else{
            //关闭热点时，如果Wi-Fi关闭，则打开
            if(!wifiManager.isWifiEnabled()){
                wifiManager.setWifiEnabled(true);
            }
        }

        try {
            Method method = wifiManager.getClass().getMethod("getWifiApConfiguration");
            //读取已有热点配置信息
            WifiConfiguration apConfig = (WifiConfiguration) method.invoke(wifiManager);

            //通过反射调用设置热点
            method = wifiManager.getClass().getMethod("setWifiApEnabled", WifiConfiguration.class, boolean.class);
            //返回热点打开状态
            result = (Boolean) method.invoke(wifiManager, apConfig, enabled);
            if (!result) {
                Toast.makeText(getCurrentActivity(), "热点创建失败，请手动创建！", Toast.LENGTH_SHORT).show();
                openAPUI();
            }
        } catch (Exception e) {
            Toast.makeText(getCurrentActivity(), "热点创建失败，请手动创建！", Toast.LENGTH_SHORT).show();
            openAPUI();
        }
    }

    /**
     * 读取热点配置信息
     */
    @ReactMethod
    public void getWifiAPConfig(Promise promise){
        String error;
        try {
            WritableMap map  = Arguments.createMap();
            Method method = wifiManager.getClass().getMethod("getWifiApConfiguration");
            WifiConfiguration apConfig = (WifiConfiguration) method.invoke(wifiManager);
            if (apConfig == null) {
                error = "未配置热点";
                map.putString("error","未配置热点");
            }
            String SSID = apConfig.SSID;
            map.putString("SSID",SSID);
            String password = apConfig.preSharedKey;
            map.putString("password",password);

            //使用apConfig.allowedKeyManagement.toString()返回{0}这样的格式，需要截取中间的具体数值
            //下面几种写法都可以
            //int index = Integer.valueOf(apConfig.allowedKeyManagement.toString().substring(1, 2));
            //int index = Integer.valueOf(String.valueOf(apConfig.allowedKeyManagement.toString().charAt(1)));
            //int index = Integer.valueOf(apConfig.allowedKeyManagement.toString().charAt(1)+"");
            int index = apConfig.allowedKeyManagement.toString().charAt(1) - '0';
            //从KeyMgmt数组中取出对应的文本
            String apType = WifiConfiguration.KeyMgmt.strings[index];
            String KeyMgmt = String.format(Locale.getDefault(), "WifiConfiguration.KeyMgmt：%s\r\n", Arrays.toString(WifiConfiguration.KeyMgmt.strings));
            String sefetype = String.format(Locale.getDefault(), "安全性：%d，%s\r\n", index, apType);
            map.putString("KeyMgmt",KeyMgmt);
            map.putString("sefetype",sefetype);
            boolean isOpen = isWifiApEnabled();
            map.putBoolean("isOpen",isOpen);
            promise.resolve(map);
        }catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
    }


}
