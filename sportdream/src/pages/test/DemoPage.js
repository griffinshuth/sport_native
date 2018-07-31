import React,{Component} from 'react'
import {connect} from 'dva'
import {
    StyleSheet,
    View,
    Text,
    Animated,
    TouchableOpacity,
    ScrollView,
    Image,
    PanResponder,
    Platform,
    NativeModules,
    Alert,
    NativeEventEmitter
} from 'react-native'

import {
    Button,
    Toast,
    WhiteSpace,
    WingBlank,
    Modal
} from 'antd-mobile'
import ImagePicker from 'react-native-image-crop-picker';


import ToolBar from '../../Components/ToolBar'
import {uploadurl} from '../../fetch'

var deviceHeight = require('Dimensions').get('window').height;
var deviceWidth = require('Dimensions').get('window').width;
var contentHeight = deviceHeight - 20 - 44;
//原生模块
var QiniuModule = NativeModules.QiniuModule;
var MultipeerAdvertiserModule = NativeModules.MultipeerAdvertiserModule;
var MultipeerBrowserModule = NativeModules.MultipeerBrowserModule;
const MultipeerBrowserModuleEmitter = new NativeEventEmitter(MultipeerBrowserModule);

var subscription = null;
import CameraType from '../../utils/CameraType'


@connect(({appNS,user})=>({appNS,user}))
export default class DemoPage extends Component{
    constructor(props){
        super(props);
        this.state = {
            currentColor:'red',
            currentAlpha:1.0,
            fadeAnim:new Animated.Value(1.0),
            xOffset:new Animated.Value(1.0),
            trans:new Animated.ValueXY(),
            imageurl:"https://facebook.github.io/react/img/logo_og.png"
        }
        this._panResponder = PanResponder.create({
            onStartShouldSetPanResponder: (evt, gestureState) => true,
            onStartShouldSetPanResponderCapture: (evt, gestureState) => true,
            onMoveShouldSetPanResponder: (evt, gestureState) => true,
            onMoveShouldSetPanResponderCapture: (evt, gestureState) => true,
            onPanResponderGrant: (evt) => {
                console.log("onResponderGrant debug!!!!!!!!!!!!!!")
                this.setState({currentColor:'green'})
            },
            onPanResponderMove:Animated.event(
                [null,{dx:this.state.trans.x,dy:this.state.trans.y}]
            ),
            onPanResponderRelease:()=>{
                this.setState({currentColor:'red'})
                Animated.spring(this.state.trans,{toValue:{x:0,y:0}}).start();
            },
            onPanResponderTerminate:()=>{
                Animated.spring(this.state.trans,{toValue:{x:0,y:0}}).start();
            }
        })
    }

    componentWillMount(){
        subscription = MultipeerBrowserModuleEmitter.addListener(
            'onMultipeerDataArrived',
            this.onMultipeerDataArrived
        );
    }

    componentWillUnmount(){
        subscription.remove();
    }

    onMultipeerDataArrived(result){
        Toast.info(JSON.stringify(result));
    }

    pickImage(){
        ImagePicker.openPicker({
            //multiple: true
            //cropping: true
        }).then(image => {
            //Toast.info(JSON.stringify(image));
            var nativepath = Platform.OS == 'ios'?image.path:image.path.substr(7);
            QiniuModule.upload(nativepath,uploadurl);
            this.setState({imageurl:image.path})
        });
    }

    gotoCameraOnStand = (cameratype)=>{
        var roomID = 10000;
        if(Platform.OS == 'ios'){
            QiniuModule.gotoCameraOnStand(this.props.appNS.clientID,cameratype,this.props.user.nickname,roomID,false,null);
        }else{
            QiniuModule.h264Record(this.props.appNS.clientID,cameratype,this.props.user.nickname,roomID,null);
        }
    }
    gotoSlowMotionCameraOnStand = (cameratype)=>{
        var roomID = 10000;
        if(Platform.OS == 'ios'){
            QiniuModule.gotoCameraOnStand(this.props.appNS.clientID,cameratype,this.props.user.nickname,roomID,true,null);
        }else{
            Toast.info("android暂时不支持慢镜头模式")
        }
    }
    gotoDirectorServer(){
        if(Platform.OS == 'ios'){
            QiniuModule.gotoDirectorServer("AgoraChannelName");
        }else{
            Toast.info("Android平台暂时不支持")
        }

    }
    gotoCommentators(){
        if(Platform.OS == 'ios'){
            QiniuModule.gotoCommentators("AgoraChannelName");
        }else{
            QiniuModule.agoraRemoteCamera("AgoraChannelName");
        }
    }
    gotoCheerleader=()=>{
        if(Platform.OS == 'ios'){
            QiniuModule.gotoCheerleader("AgoraChannelName");
        }else{
            QiniuModule.agoraRemoteCamera("AgoraChannelName");
        }
    }
    gotoLiveCommentators(){
        if(Platform.OS == 'ios'){
            QiniuModule.gotoLiveCommentators(this.props.appNS.clientID,0,"haimeng",10000);
        }else{
            QiniuModule.liveCommentorsActivity(this.props.appNS.clientID,0,"haimeng",10000);
        }
    }

    advertise(){
        MultipeerAdvertiserModule.advertise();
        Toast.info("开始广播")
    }

    browser(){
        MultipeerBrowserModule.browser();
    }

    sendData(){
        MultipeerAdvertiserModule.sendData("hello world")
    }

    render(){
        return (
            <View style={styles.container}>
                <ToolBar title="Demo" navigation={this.props.navigation}/>
                <ScrollView showsVerticalScrollIndicator={false} style={{flex:1}}>
                    <Image source={{uri:this.state.imageurl}} style={{width:100,height:100}}/>
                    <Text>{this.state.imageurl}</Text>
                    <Button onClick={()=>this.pickImage()}>选择图片</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.advertise()}>IOS Multipeer 广播服务</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.browser()}>IOS Multipeer 浏览服务</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.sendData()}>IOS Multipeer 发送数据</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoCameraOnStand(0)/*Modal.operation([
                        { text: '主机位', onPress: () => this.gotoCameraOnStand(CameraType.CameraType_MAIN) },
                        { text: '持球人机位', onPress: () => this.gotoCameraOnStand(CameraType.CameraType_BALL) },
                        { text: '局部机位', onPress: () => this.gotoCameraOnStand(CameraType.CameraType_PART)},
                        { text: '特写机位', onPress: () => this.gotoCameraOnStand(CameraType.CameraType_FEATURE)},
                        { text: '观众机位', onPress: () => this.gotoCameraOnStand(CameraType.CameraType_AUDIENCE)},
                        { text: '自由机位', onPress: () => this.gotoCameraOnStand(CameraType.CameraType_MOVE)},
                    ])*/}>赛场机位</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoSlowMotionCameraOnStand(0)}>赛场慢镜头</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoDirectorServer()}>导播服务器</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoCommentators()}>演播室</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoCheerleader()}>主播</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoLiveCommentators()}>现场解说</Button>
                </ScrollView>
            </View>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        alignItems:'center',
        //justifyContent:'center'
    },
    button:{
        marginTop:10,
        alignItems:'center',
        justifyContent:'center',
        width:200,
        height:50,
        backgroundColor:'#ccc'
    }
})