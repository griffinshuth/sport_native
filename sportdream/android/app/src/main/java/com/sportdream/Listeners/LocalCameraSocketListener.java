package com.sportdream.Listeners;

/**
 * Created by lili on 2018/4/26.
 */

public interface LocalCameraSocketListener {
    void OnDirectServerConnected();
    void OnDirectServerDisconnected();
    void OnHighlightServerConnected();
    void OnHighlightServerDisconnected();
    void OnHighlightServerInfo(String message);
    void OnMediaCodecReset(boolean isBig);
}
