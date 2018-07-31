import React, { Component } from 'react';
import {
    AppRegistry,
    StyleSheet,
    Text,
    View,
    TouchableHighlight,
    NativeAppEventEmitter,
    NativeEventEmitter,
    NativeModules,
    Platform,
    PermissionsAndroid,
    ListView,
    ScrollView,
    AppState,
    requireNativeComponent,
    Dimensions
} from 'react-native';
import {
    Toast,
    WhiteSpace,
    Button
} from 'antd-mobile'
import Orientation from 'react-native-orientation';

import ToolBar from '../../Components/ToolBar'
import {AudioRecorder, AudioUtils} from 'react-native-audio';
var BaiduASRModule = NativeModules.BaiduASRModule; //ios
import CaptureVideoSocketView from '../../NativeViews/CaptureVideoSocketView'

export default class App extends Component {
    constructor(props){
        super(props);
        this.state = {
            currentMetering:null,
            currentTime:null,
            count:0,
            capture:false,
            captureWidth:0,
            captureHeight:0
        }
    }
    componentDidMount() {
        Orientation.lockToLandscape();
        var {height, width} = Dimensions.get('window');
        this.setState({captureWidth:height,captureHeight:width})
        //测试分贝
        //var audioPath = AudioUtils.DocumentDirectoryPath + '/testaudio.aac';
        var audioPath = "/dev/null";
        AudioRecorder.prepareRecordingAtPath(audioPath, {
            SampleRate: 22050,
            Channels: 1,
            AudioQuality: "Low",
            AudioEncoding: "aac",
            AudioEncodingBitRate: 32000,
            MeteringEnabled:true
        });
        AudioRecorder.onProgress = (data) => {
            console.log(data);
            if(this.state.currentTime == null && this.state.currentMetering == null){
                this.setState({
                    currentMetering:data.currentMetering,
                    currentTime:data.currentTime
                })
                this.countTime = data.currentTime;
            }else{
                    if(data.currentTime-this.countTime > 1){
                        this.setState({
                            currentMetering:data.currentMetering,
                            currentTime:data.currentTime
                        })
                        if(data.currentMetering>-15){
                            var result = this.state.count+1;
                            this.setState({
                                count:result
                            })
                            BaiduASRModule.speak(result+"");
                            this.countTime = data.currentTime;
                        }
                    }
            }

        };
        AudioRecorder.onFinished = (data) => {
            // Android callback comes in the form of a promise instead.
            if (Platform.OS === 'ios') {

            }
        };
        AudioRecorder.startRecording();
    }

    componentWillUnmount() {
        AudioRecorder.stopRecording();
        Orientation.lockToPortrait();
    }

    startCapture = ()=>{
        this.setState({capture:true})
    }

    render(){
        return (<View>
            <View>
                <CaptureVideoSocketView style={{position:'absolute',width:this.state.captureWidth,height:this.state.captureHeight}} capture={this.state.capture} />
                <Text>{this.state.currentMetering}</Text>
                <WhiteSpace/>
                <Text>{this.state.currentTime}</Text>
                <WhiteSpace/>
                <Text>{this.state.count}</Text>
                <Button onClick={this.startCapture}>开始预览</Button>
            </View>
        </View>)
    }
}


















































