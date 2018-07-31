package com.sportdream.DreamSDK.Delegate;

import com.sportdream.network.LocalClientInfo;

/**
 * Created by lili on 2018/5/2.
 */

public interface LocalServerCoreDelegate {
    public void LocalServerListening();
    public void LocalServerRemoteClientAccepted();
    public void LocalServerRemoteClientLogined(LocalClientInfo info);
    public void LocalServerRemoteClientClosed(LocalClientInfo info);
    public void LocalServerClosed();
    public void LocalServerRemoteClientDataReceived(LocalClientInfo info,short PacketID,byte[] data);
}
