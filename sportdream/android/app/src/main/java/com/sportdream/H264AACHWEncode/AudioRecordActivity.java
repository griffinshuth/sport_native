package com.sportdream.H264AACHWEncode;

import android.app.Activity;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.baidu.mapapi.map.Text;
import com.sportdream.DreamSDK.AACEncoder;
import com.sportdream.DreamSDK.AudioRecorder;
import com.sportdream.DreamSDK.Delegate.AACEncoderDelegate;
import com.sportdream.DreamSDK.Delegate.AudioRecorderDelegate;
import com.sportdream.R;
import com.sportdream.network.LocalWifiNetworkThread;
import com.sportdream.network.LocalWifiSocketHandler;

/**
 * Created by lili on 2018/2/3.
 */

public class AudioRecordActivity extends Activity implements LocalWifiSocketHandler,AACEncoderDelegate,AudioRecorderDelegate {

    private static final short COMMENT_AUDIO = 8;

    private AudioRecorder mRecorder;
    private AACEncoder mAudioEncoder;
    private LocalWifiNetworkThread mNetwork;
    private Boolean isServerConnected;
    private Boolean isRecording;
    private TextView record_status;
    private TextView network_status;
    private Button record_btn;
    private AudioTrack audioTrack;

    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        setContentView(R.layout.live_commentors);

        record_btn = (Button)findViewById(R.id.record_btn);
        record_status = (TextView)findViewById(R.id.record_status);
        network_status = (TextView)findViewById(R.id.network_status);
        isServerConnected = false;
        isRecording = false;

        mRecorder = new AudioRecorder();
        mRecorder.setDelegate(this);
        mAudioEncoder = new AACEncoder();
        mAudioEncoder.setDelegate(this);
        mNetwork = new LocalWifiNetworkThread(this);
        mNetwork.start();
        mNetwork.searchServer();

        int minBufferSize = AudioRecord.getMinBufferSize(44100, AudioFormat.CHANNEL_CONFIGURATION_MONO,AudioFormat.ENCODING_PCM_16BIT);
        audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC,44100, AudioFormat.CHANNEL_CONFIGURATION_MONO, AudioFormat.ENCODING_PCM_16BIT,minBufferSize,AudioTrack.MODE_STREAM);
        audioTrack.play();
    }

    @Override
    protected void onStart(){
        super.onStart();
    }

    @Override
    protected void onResume(){
        super.onResume();
    }

    @Override
    protected void onPause(){
        super.onPause();
    }

    @Override
    protected void onStop(){
        super.onStop();
    }

    @Override
    protected void onDestroy(){

        super.onDestroy();
        if(isRecording){
            mRecorder.stop();
            mAudioEncoder.destroy();
        }
        audioTrack.stop();
        //关闭网络线程
        if(mNetwork != null){
            mNetwork.exit();
            try {
                mNetwork.join();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            mNetwork = null;
        }
    }

    public void Comment(View v){
        if(!isServerConnected){
            Toast.makeText(this,"server not connected",Toast.LENGTH_LONG).show();
            return;
        }
        if(!isRecording){
            mAudioEncoder.init();
            mRecorder.start();
            isRecording = true;
            record_status.setText("录音中");
            record_btn.setText("暂停录音");
        }else{
            isRecording = false;
            record_status.setText("录音暂停");
            record_btn.setText("开始录音");
            mRecorder.stop();
            mAudioEncoder.destroy();
        }
    }

    private void send(short packetID,byte[] data){
        mNetwork.sendData(packetID,data);
    }

    //delegate
    public void DirectServerConnected(){
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                isServerConnected = true;
                network_status.setText("服务器连接成功");
            }
        });
    }
    public void DataReceived(short PacketID,byte[] data){

    }

    public void dataWithADTSFromAACEncoder(byte[] aacData)
    {

    }
    public void dataWithoutADTSFromAACEncoder(byte[] aacData){
        send(COMMENT_AUDIO,aacData);
    }

    public void DataFromAudioRecorder(byte[] pcmData){
        //收到录音的数据，开始编码
        //audioTrack.write(pcmData,0,pcmData.length);
        //return;
        if(isRecording){
            mAudioEncoder.encode(pcmData);
        }
    }
}
