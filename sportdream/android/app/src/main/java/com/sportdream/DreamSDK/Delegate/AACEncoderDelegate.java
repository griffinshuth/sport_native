package com.sportdream.DreamSDK.Delegate;

/**
 * Created by lili on 2018/2/5.
 */

public interface AACEncoderDelegate {
    public void dataWithADTSFromAACEncoder(byte[] aacData);
    public void dataWithoutADTSFromAACEncoder(byte[] aacData);
}
