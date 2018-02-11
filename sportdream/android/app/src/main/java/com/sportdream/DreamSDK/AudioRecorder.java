package com.sportdream.DreamSDK;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;

import com.sportdream.DreamSDK.Delegate.AudioRecorderDelegate;

import java.nio.ByteBuffer;

/**
 * Created by lili on 2018/2/3.
 */

public class AudioRecorder {
    private AudioRecord record;
    private AudioRecorderDelegate delegate;
    private Thread readThread;
    private Boolean isPlaying;
    private int minBufferSize;
    private byte[] audioBuffer;
    public AudioRecorder(){
        isPlaying = false;
    }

    public void setDelegate(AudioRecorderDelegate delegate){
        this.delegate = delegate;
    }

    public void start(){
        isPlaying = true;
        minBufferSize = AudioRecord.getMinBufferSize(44100, AudioFormat.CHANNEL_CONFIGURATION_MONO,AudioFormat.ENCODING_PCM_16BIT);
        audioBuffer = new byte[minBufferSize];
        record = new AudioRecord(MediaRecorder.AudioSource.MIC,44100, AudioFormat.CHANNEL_CONFIGURATION_MONO,AudioFormat.ENCODING_PCM_16BIT,minBufferSize);
        readThread = new Thread(new Runnable() {
            @Override
            public void run() {
                while (isPlaying){
                    int len = record.read(audioBuffer,0,minBufferSize);
                    if(len<0){
                        break;
                    }
                    ByteBuffer buffer = ByteBuffer.allocate(len);
                    for(int i=0;i<len;i++){
                        buffer.put(audioBuffer[i]);
                    }
                    buffer.flip();
                    byte[] pcmData = new byte[len];
                    buffer.get(pcmData);
                    delegate.DataFromAudioRecorder(pcmData);
                }
            }
        });
        record.startRecording();
        readThread.start();
    }

    public void stop(){
        isPlaying = false;
        record.stop();
        record.release();
    }
}
