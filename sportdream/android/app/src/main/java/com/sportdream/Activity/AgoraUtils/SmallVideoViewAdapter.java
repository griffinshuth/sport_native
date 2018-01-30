package com.sportdream.Activity.AgoraUtils;

import android.content.Context;
import android.util.DisplayMetrics;
import android.view.SurfaceView;
import android.view.WindowManager;

import java.util.HashMap;

/**
 * Created by lili on 2018/1/22.
 */

public class SmallVideoViewAdapter extends VideoViewAdapter {
    public SmallVideoViewAdapter(Context context, int exceptedUid, HashMap<Integer, SurfaceView> uids, VideoViewEventListener listener) {
        super(context, exceptedUid, uids, listener);
    }

    @Override
    protected void customizedInit(HashMap<Integer,SurfaceView> uids,boolean force){
        for(HashMap.Entry<Integer,SurfaceView> entry : uids.entrySet()){
            if(entry.getKey() != exceptedUid){
                entry.getValue().setZOrderOnTop(true);
                entry.getValue().setZOrderMediaOverlay(true);
                mUsers.add(new VideoStatusData(entry.getKey(), entry.getValue(), VideoStatusData.DEFAULT_STATUS, VideoStatusData.DEFAULT_VOLUME));

            }
        }

        if(force || mItemHeight == 0 || mItemWidth == 0){
            WindowManager windowManager = (WindowManager)mContext.getSystemService(Context.WINDOW_SERVICE);
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getMetrics(outMetrics);
            mItemWidth = outMetrics.widthPixels/4;
            mItemHeight = outMetrics.heightPixels/4;
        }
    }

    @Override
    public void notifyUiChanged(HashMap<Integer, SurfaceView> uids, int uidExcluded, HashMap<Integer, Integer> status, HashMap<Integer, Integer> volume) {
        mUsers.clear();
        for (HashMap.Entry<Integer, SurfaceView> entry : uids.entrySet()) {
            if (entry.getKey() != uidExcluded) {
                entry.getValue().setZOrderOnTop(true);
                entry.getValue().setZOrderMediaOverlay(true);
                mUsers.add(new VideoStatusData(entry.getKey(), entry.getValue(), VideoStatusData.DEFAULT_STATUS, VideoStatusData.DEFAULT_VOLUME));
            }
        }
        notifyDataSetChanged();
    }

    public int getExceptedUid() {
        return exceptedUid;
    }

}
