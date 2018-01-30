import React,{Component} from 'react'
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
    WingBlank
} from 'antd-mobile'
import ImagePicker from 'react-native-image-crop-picker';


import ToolBar from '../../Components/ToolBar'
import {get,post} from '../../fetch'

var deviceHeight = require('Dimensions').get('window').height;
var deviceWidth = require('Dimensions').get('window').width;
var contentHeight = deviceHeight - 20 - 44;
//原生模块
var CalendarManager = NativeModules.CalendarManager;
var ToastExample = NativeModules.ToastExample;
var ImagePickerModule = NativeModules.ImagePickerModule;
var QiniuModule = NativeModules.QiniuModule;
var ClassicBlueToothModule = NativeModules.ClassicBlueToothModule;
var MultipeerAdvertiserModule = NativeModules.MultipeerAdvertiserModule;
var MultipeerBrowserModule = NativeModules.MultipeerBrowserModule;
const MultipeerBrowserModuleEmitter = new NativeEventEmitter(MultipeerBrowserModule);

async function getCalendar(){
    try{
        var events = await CalendarManager.getCalendar();
        Toast.info(JSON.stringify(events))
    }catch(e){
        Toast.info(JSON.stringify(e));
    }
}

var subscription = null;

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

    startAnimation(){
        this.state.currentAlpha = this.state.currentAlpha == 1.0?0.0:1.0;
        Animated.timing(
            this.state.fadeAnim,
            {
                toValue:this.state.currentAlpha
            }
        ).start();
        if(Platform.OS == "android"){
            ToastExample.show("mangguo",NativeModules.ToastExample.SHORT)
        }
    }

    pickImage(){
        ImagePicker.openPicker({
            //multiple: true
            //cropping: true
        }).then(image => {
            //Toast.info(JSON.stringify(image));
            var nativepath = Platform.OS == 'ios'?image.path:image.path.substr(7);
            QiniuModule.upload(nativepath);
            this.setState({imageurl:image.path})
        });
    }

    testPromise(){
        //getCalendar();
        Toast.info(CalendarManager.TeamSize);
    }

    goToZhibo = async()=>{
        var push = await post("/getPublishURL",{streamname:"test2"})
        QiniuModule.Zhibo(push.url);
    }
    goToZhiboPlay = async()=>{
        var play = await post("/getRTMPPlayURL",{streamname:"test2"})
        QiniuModule.playZhibo(play.url);
    }
    goToH264Record = async()=>{
        //var push = await post("/getPublishURL",{streamname:"test2"})
        QiniuModule.h264Record(""/*push.url*/);
    }
    goToLocalNetwork(){
        QiniuModule.gotoLocalNetwork();
    }
    gotoVideoChat(){
        QiniuModule.gotoVideoChat();
    }
    gotoMatchDirector(){
        QiniuModule.gotoMatchDirector();
    }
    gotoARCameraView(){
        QiniuModule.gotoARCameraView();
    }
    gotoCameraOnStand(){
        QiniuModule.gotoCameraOnStand();
    }
    gotoDirectorServer(){
        QiniuModule.gotoDirectorServer();
    }
    gotoCommentators(){
        QiniuModule.gotoCommentators();
    }
    gotoLiveCommentators(){
        QiniuModule.gotoLiveCommentators();
    }
    async getBlueToothInfo(){
        var info = await ClassicBlueToothModule.getBlueToothInfo();
        Toast.info(JSON.stringify(info));
    }

    async openBluetooth(){
        try{
            var code = await ClassicBlueToothModule.openBluetooth();
            Toast.info(code);
        }catch(e){
            console.log(e);
        }
    }

    async openDiscoverable(){
        var code = await ClassicBlueToothModule.openDiscoverable();
        Toast.info(code);
    }

    async testInit(){
        var result = await MultipeerAdvertiserModule.testInit();
        Toast.info(JSON.stringify(result));
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
                    <Animated.Text
                        style={{
                            opacity:this.state.fadeAnim,
                            transform:[
                                {
                                    translateY:this.state.fadeAnim.interpolate({
                                        inputRange:[0,1],
                                        outputRange:[60,0]
                                    })
                                },
                                {
                                    scale:this.state.fadeAnim
                                }
                            ]
                        }}
                    >
                        Welcome to Sport World
                    </Animated.Text>
                    <TouchableOpacity onPress = {()=> this.startAnimation()} style={styles.button}>
                        <Text>Start Animation</Text>
                    </TouchableOpacity>

                    {/*<ScrollView
                horizontal={true}
                showHorizontalScrollIndicator={false}
                style={{
                    width:deviceWidth,
                    height:contentHeight
                }}
                onScroll={Animated.event(
                    [{nativeEvent:{contentOffset:{x:this.state.xOffset}}}]
                )}
                scrollEventThrottle={100}
                >
                    <Animated.Image
                    source={require('../assets/images/shoot.png')}
                    style={{
                       height:contentHeight,
                       width:deviceWidth,
                       opacity:this.state.xOffset.interpolate({
                           inputRange:[0,deviceWidth],
                           outputRange:[1.0,0.0]
                       })
                    }}
                    resizeMode="cover"
                    >
                    </Animated.Image>
                    <Image source={require('../assets/images/match.png')} style={{height:contentHeight,width:deviceWidth}} resizeMode="cover" />
                    <Image source={require('../assets/images/relation.png')} style={{height:contentHeight,width:deviceWidth}} resizeMode="cover" />
                </ScrollView>*/}

                    <Animated.View
                        style={{
                            width:100,
                            height:100,
                            borderRadius:50,
                            backgroundColor:this.state.currentColor,
                            transform:[
                                {translateY:this.state.trans.y},
                                {translateX:this.state.trans.x}
                            ]
                        }}
                        {...this._panResponder.panHandlers}
                    >

                    </Animated.View>
                    <Image source={{uri:this.state.imageurl}} style={{width:100,height:100}}/>
                    <View>
                        <Text>腾讯体育10月8日讯 欧洲中部时间本周六晚间，
                            世界杯欧洲区预选赛A组进行了第9轮的3场比赛，
                            最终瑞典8-0横扫卢森堡，“北欧海盗”依然排在本组第2位；
                            而荷兰则在客场3-1击败白俄罗斯，目前橙衣军团以3分之差位列小组第3。
                            不过，虽然理论上荷兰队依然有在最后一轮的直接交锋中反超瑞典的可能性，
                            不过发生这种情况的概率，却比中国队击败德国队的概率还要更低。</Text>
                    </View>
                    <Text>{this.state.imageurl}</Text>
                    <Button onClick={()=>this.pickImage()}>选择图片</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.testPromise()}>ios promise</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.goToZhibo()}>七牛直播</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.goToZhiboPlay()}>七牛直播播放</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.goToH264Record()}>H264录制</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.goToLocalNetwork()}>本地网络</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.getBlueToothInfo()}>Android 获得蓝牙信息</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.openBluetooth()}>打开蓝牙</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.openDiscoverable()}>打开可发现性</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.testInit()}>测试IOS模块初始化</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.advertise()}>广播服务</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.browser()}>浏览服务</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.sendData()}>发送数据</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoVideoChat()}>视频聊天</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoMatchDirector()}>导播系统</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoARCameraView()}>多主播切换系统</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoCameraOnStand()}>三脚架机位</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoDirectorServer()}>导播服务器</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.gotoCommentators()}>演播室解说</Button>
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