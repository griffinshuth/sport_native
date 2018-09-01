import React from 'react'
import {
    StyleSheet,
    View,
    Text,
    requireNativeComponent,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    Platform,
    Dimensions
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast,
    Flex
} from 'antd-mobile'
import Orientation from 'react-native-orientation';

import ToolBar from '../../Components/ToolBar'
import AgorachatNativeView from '../../NativeViews/AgorachatView'
var AgorachatModule = NativeModules.AgorachatViewManager;
import {get, post,serverurl} from '../../fetch'
import io from 'socket.io-client'
import {clientEvent,serverEvent} from '../../utils/socketEvent'

var BaiduASRModule = NativeModules.BaiduASRModule;
const BaiduASRModuleEmitter = new NativeEventEmitter(BaiduASRModule);
import {connect} from 'dva'

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            agorauid:null,
            otherAgoraUid:null,
            myscore:0,
            otherscore:0,
            players : [],
            isPushing:false,
            isEnterMatch:false,
            currentTime:0,
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

    onVoiceRecognize = (result)=>{
        if(Platform.OS == 'ios'){
            var command = JSON.parse(result.data).results_recognition[0];
        }else{
            var command = result.RecognizeResult;
        }
        Toast.info(command);
        if(command == "sorry"){
            BaiduASRModule.speak("投失")
        }
        if(command == "ok"){
            this.socket.emit(serverEvent.ShootMatchUpdateScore,{},(data)=>{
                if(data.error){
                    Toast.info(data.error);
                }else{
                    BaiduASRModule.speak("命中")
                    this.setState({myscore:this.state.myscore+1})
                }
            })
        }
    }

    componentWillMount(){
        AgorachatModule.initAgoraWithoutAudio();

        if(Platform.OS == 'ios'){
            BaiduASRModule.startListen();
        }else{
            BaiduASRModule.init();
            BaiduASRModule.initTTS();
        }

        this.subscription = BaiduASRModuleEmitter.addListener(
            'onVoiceRecognize',
            this.onVoiceRecognize
        );
    }

    componentDidMount(){
        this.setState({players:[...this.state.players,0]})
        Orientation.lockToLandscape();
        AgorachatModule.joinChannel("test")
        this.joinChannelSuccess_subscription = NativeAppEventEmitter.addListener(
            'joinChannelSuccess',
            (data)=>{
                //Toast.info(data.myuid);
                this.setState({agorauid:data.myuid});
            }
        )
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

        this.socket = io(serverurl,{
            //transports: ['websocket'],
        });
        this.socket.on("reconnect",()=>{
            console.log("reconnect")
        })

        this.socket.on(clientEvent.updatebeforetime,(data)=>{
            if(data.time == 0){
                BaiduASRModule.speak("开始")
            }else{
                BaiduASRModule.speak(data.time+"")
            }
        })

        this.socket.on(clientEvent.updatecountdowntime,(data)=>{
            if(data.time == 0){
                BaiduASRModule.speak("比赛结束")
            }
            this.setState({currentTime:data.time})
        })

        this.socket.on(clientEvent.updateShootScore,(data)=>{
            if(data.agorauid != this.state.agorauid){
                this.setState({otherscore:data.score})
            }
        })
        setTimeout(()=>{
            var matchuid = this.props.navigation.state.params.matchuid;
            var token = this.props.appNS.token;
            this.socket.emit(serverEvent.enterShootMatch,{token:token,matchuid:matchuid,agorauid:this.state.agorauid},(data)=>{
                if(data.error){
                    Toast.info(data.error);
                    this.setState({isEnterMatch:false})
                }else{
                    this.setState({isEnterMatch:true})
                }
            })
        },3000)
    }

    componentWillUnmount(){
        Orientation.lockToPortrait();
        AgorachatModule.leaveChannel();
        this.firstRemoteVideoDecoded_subscription.remove();
        this.didOffline_subscription.remove();

        AgorachatModule.destroyAgora();

        this.socket.disconnect();

        if(Platform.OS == 'ios'){
            BaiduASRModule.endListen();
        }else{
            BaiduASRModule.destroy();
            BaiduASRModule.destroyTTS();
        }
        this.subscription.remove();
    }

    startMatch = ()=>{
        this.socket.emit(serverEvent.startShootMatch,{},(data)=>{
            if(data.error){
                Toast.info(data.error);
            }else{
                //AgorachatModule.startRCTRecord();
                this.setState({isPushing:true});
            }
        })
    }

    render(){
        var {height, width} = Dimensions.get('window');
        return (
            <View style={{flex:1}}>
                <Flex>
                    {
                        this.state.players.map((item)=>{
                            return <Flex.Item key={item}>
                                <AgorachatNativeView uid={item} style={{height:height}}/>
                            </Flex.Item>
                        })
                    }
                </Flex>
                <View style={{position:'absolute',bottom:0,right:0}}>
                    <Text>
                        {this.state.isEnterMatch?"赛场进入成功":"没有进入赛场"}
                    </Text>
                    <Text>{this.state.currentTime}</Text>
                    <Text>{"本方得分："+this.state.myscore}</Text>
                    <Text>{"对方得分："+this.state.otherscore}</Text>
                    <WhiteSpace/>
                    <WhiteSpace/>
                    <WhiteSpace/>
                    <WhiteSpace/>
                    <WhiteSpace/>
                    <Button onClick={()=>{this.props.navigation.goBack()}} size="large">离开房间</Button>
                </View>
            </View>);
    }
}