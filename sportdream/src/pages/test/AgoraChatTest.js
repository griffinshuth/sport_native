import React from 'react'
import {
    StyleSheet,
    View,
    Text,
    requireNativeComponent,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    Platform
} from 'react-native'
import {
    WhiteSpace,
    Toast
} from 'antd-mobile'
import Orientation from 'react-native-orientation';

import ToolBar from '../../Components/ToolBar'
import Button from "antd-mobile/es/button/index.native";
var AgorachatView = requireNativeComponent('AgorachatView', null);
var AgorachatModule = NativeModules.AgorachatViewManager;

//百度语音识别
var BaiduASRModule = NativeModules.BaiduASRModule;
const BaiduASRModuleEmitter = new NativeEventEmitter(BaiduASRModule);

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            players : [],
            isPushing:false
        }

    }

    onVoiceRecognize = (result)=>{
        Toast.info(JSON.parse(result.data).results_recognition[0],1);
        console.log(result.data)
        var command = JSON.parse(result.data).results_recognition[0];
        if(command == "sorry"){
            BaiduASRModule.speak(command)
        }
        if(command == "ok"){
            BaiduASRModule.speak(command)
        }
    }

    record = ()=>{
        if(!this.state.isPushing){
            AgorachatModule.startRCTRecord();
        }else{
            AgorachatModule.stopRCTRecord();
        }
        this.setState({isPushing:!this.state.isPushing});
    }

    componentWillMount(){
        AgorachatModule.initAgora();
    }

    componentDidMount(){
        if(Platform.OS != 'ios'){
            return;
        }
        Orientation.lockToLandscape();
        AgorachatModule.joinChannel("test")
        this.firstRemoteVideoDecoded_subscription = NativeAppEventEmitter.addListener(
            'firstRemoteVideoDecoded',
            (data) => {
                this.state.players.push(data.uid);
                this.setState({players:this.state.players})
            }
        );

        this.didOffline_subscription = NativeAppEventEmitter.addListener(
            'didOffline',
            (data) => {
                var index = this.state.players.indexOf(data.uid);
                if(index>=0){
                    this.state.players.splice(index,1);
                    this.setState({players:this.state.players})
                }
            }
        );

        //
        /*BaiduASRModule.startListen();
        this.subscription = BaiduASRModuleEmitter.addListener(
            'onVoiceRecognize',
            this.onVoiceRecognize
        );*/
    }

    componentWillUnmount(){
        if(Platform.OS != 'ios'){
            return;
        }
        Orientation.lockToPortrait();
        AgorachatModule.leaveChannel();
        this.firstRemoteVideoDecoded_subscription.remove();
        this.didOffline_subscription.remove();

        AgorachatModule.destroyAgora();

        //
        /*BaiduASRModule.endListen();
        this.subscription.remove();*/
    }

    render(){
        return (
        <View style={{flex:1}}>
            <AgorachatView uid={0} style={{width:160,height:120}}/>
            {
                this.state.players.map((item)=>{
                    return <View key={item}>
                        <WhiteSpace/>
                        <AgorachatView uid={item} style={{width:160,height:120}}/>
                    </View>
                })
            }
            <View style={{position:'absolute',bottom:0,right:0}}>
                <Button onClick={()=>{this.props.navigation.goBack()}} size="large">返回</Button>
                <WhiteSpace/>
                <Button onClick={this.record} size="large">{this.state.isPushing?"stop":"start"}</Button>
            </View>
        </View>);
    }
}