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
    requireNativeComponent
} from 'react-native';
import {
    Toast,
    WhiteSpace
} from 'antd-mobile'

import ToolBar from '../../Components/ToolBar'
import {AudioRecorder, AudioUtils} from 'react-native-audio';
var BaiduSpeechModule = NativeModules.BaiduSpeechModule; //android
var BaiduASRModule = NativeModules.BaiduASRModule; //ios

export default class App extends Component {
    constructor(props){
        super(props);
        this.state = {
            currentMetering:null,
            currentTime:null,
            count:0,
        }
    }
    componentDidMount() {
        if (Platform.OS === 'android' && Platform.Version >= 23) {
            PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION).then((result) => {
                if (result) {
                    console.log("Permission is OK");
                } else {
                    PermissionsAndroid.requestPermission(PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION).then((result) => {
                        if (result) {
                            console.log("User accept");
                        } else {
                            console.log("User refuse");
                        }
                    });
                }
            });
        }

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
    }

    render(){
        return (<View>
            <ToolBar title="BLE搜索" navigation={this.props.navigation}/>
            <View>
                <Text>{this.state.currentMetering}</Text>
                <WhiteSpace/>
                <Text>{this.state.currentTime}</Text>
                <WhiteSpace/>
                <Text>{this.state.count}</Text>
            </View>
        </View>)
    }
}


















































