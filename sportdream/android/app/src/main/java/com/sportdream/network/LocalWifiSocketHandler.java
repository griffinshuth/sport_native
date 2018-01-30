package com.sportdream.network;

/**
 * Created by lili on 2018/1/22.
 */

public interface LocalWifiSocketHandler {
    public void DirectServerConnected();
    public void DataReceived(short PacketID,byte[] data);
}
