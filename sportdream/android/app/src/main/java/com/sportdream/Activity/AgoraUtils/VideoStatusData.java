package com.sportdream.Activity.AgoraUtils;

import android.view.SurfaceView;

/**
 * Created by lili on 2018/1/18.
 */

public class VideoStatusData {
    public static final int DEFAULT_STATUS = 0;
    public static final int VIDEO_MUTED = 1;
    public static final int AUDIO_MUTED = VIDEO_MUTED << 1;
    public static final int DEFAULT_VOLUME = 0;

    public int mUid;

    public SurfaceView mView;

    public int mStatus;

    public int mVolume;

    public VideoStatusData(int uid, SurfaceView view, int status, int volume) {
        this.mUid = uid;
        this.mView = view;
        this.mStatus = status;
        this.mVolume = volume;
    }

    @Override
    public String toString() {
        return "VideoStatusData{" +
                "mUid=" + (mUid & 0xFFFFFFFFL) +
                ", mView=" + mView +
                ", mStatus=" + mStatus +
                ", mVolume=" + mVolume +
                '}';
    }
}
