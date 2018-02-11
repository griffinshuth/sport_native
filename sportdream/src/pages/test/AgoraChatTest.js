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
import ToolBar from '../../Components/ToolBar'
var AgorachatView = requireNativeComponent('AgorachatView', null);
var AgorachatModule = NativeModules.AgorachatViewManager;

//百度语音识别
var BaiduASRModule = NativeModules.BaiduASRModule;
const BaiduASRModuleEmitter = new NativeEventEmitter(BaiduASRModule);

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            players : []
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

    componentDidMount(){
        if(Platform.OS != 'ios'){
            return;
        }
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
        BaiduASRModule.startListen();
        this.subscription = BaiduASRModuleEmitter.addListener(
            'onVoiceRecognize',
            this.onVoiceRecognize
        );
    }

    componentWillUnmount(){
        if(Platform.OS != 'ios'){
            return;
        }
        AgorachatModule.leaveChannel();
        this.firstRemoteVideoDecoded_subscription.remove();
        this.didOffline_subscription.remove();

        //
        BaiduASRModule.endListen();
        this.subscription.remove();
    }

    render(){
        return (
        <View style={{flex:1}}>
            <ToolBar title="视频聊天" navigation={this.props.navigation}/>
            <AgorachatView uid={0} style={{width:240,height:320}}/>
            {
                this.state.players.map((item)=>{
                    return <View key={item}>
                        <WhiteSpace/>
                        <AgorachatView uid={item} style={{width:120,height:160}}/>
                    </View>
                })
            }
        </View>);
    }
}