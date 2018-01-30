package com.sportdream.Activity.AgoraUtils;

import android.content.Context;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;

/**
 * Created by lili on 2018/1/22.
 */

public class OnDoubleTapListener implements View.OnTouchListener {

    private final class GestureListener extends GestureDetector.SimpleOnGestureListener {

        @Override
        public boolean onDown(MotionEvent e) {
            return true;
        }

        @Override
        public boolean onDoubleTap(MotionEvent e) {
            OnDoubleTapListener.this.onDoubleTap(mView, e);
            return super.onDoubleTap(e);
        }

        public boolean onSingleTapUp(MotionEvent e) {
            OnDoubleTapListener.this.onSingleTapUp();
            return super.onSingleTapUp(e);
        }
    }

    private GestureDetector mGestrueDetector;
    private View mView;

    public OnDoubleTapListener(Context c){
        mGestrueDetector = new GestureDetector(c, new GestureListener());
    }

    public boolean onTouch(final View view,final MotionEvent motionEvent){
        mView = view;
        return mGestrueDetector.onTouchEvent(motionEvent);
    }

    public void onDoubleTap(View view, MotionEvent e) {

    }

    public void onSingleTapUp() {

    }
}
