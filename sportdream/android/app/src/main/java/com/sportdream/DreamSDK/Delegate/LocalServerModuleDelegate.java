package com.sportdream.DreamSDK.Delegate;

import com.sportdream.network.LocalClientInfo;

/**
 * Created by lili on 2018/5/4.
 */

public interface LocalServerModuleDelegate {
    public void LocalServerModuleListening();
    public void LocalServerModuleRemoteClientAccepted();
    public void LocalServerModuleRemoteClientLogined(LocalClientInfo info);
    public void LocalServerModuleRemoteClientClosed(LocalClientInfo info);
    public void LocalServerModuleClosed();
    public void LocalServerModuleRemoteClientDataReceived(String deviceID,String json);
}
