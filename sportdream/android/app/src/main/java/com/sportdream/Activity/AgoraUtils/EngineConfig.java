package com.sportdream.Activity.AgoraUtils;

/**
 * Created by lili on 2018/1/18.
 */

public class EngineConfig {
    public int mClientRole;

    public int mVideoProfile;

    public int mUid;

    public String mChannel;

    public void reset() {
        mChannel = null;
    }

    EngineConfig() {
    }
}
