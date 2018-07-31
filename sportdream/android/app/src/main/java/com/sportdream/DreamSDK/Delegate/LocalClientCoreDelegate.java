package com.sportdream.DreamSDK.Delegate;

/**
 * Created by lili on 2018/5/2.
 */

public interface LocalClientCoreDelegate {
    public void LocalClientConnected();
    public void LocalClientConnectFailed();
    public void LocalClientDisconnected();
    public void LocalClientDataReceived(short PacketID,byte[] data);
}
