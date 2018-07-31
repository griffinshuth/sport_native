import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    TextInput,
    Platform,
    ScrollView,
    Alert,
    TouchableHighlight
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast,
    Card,
    WingBlank,
    List,
    InputItem,
    SearchBar,
    Modal,
    Drawer,
    Tabs,
    Badge,
    NoticeBar
} from 'antd-mobile'

import {NativeModules} from 'react-native'
var ChatModule = NativeModules.ChatModule;
var QiniuModule = NativeModules.QiniuModule;
var WiFiAPModule = NativeModules.WiFiAPModule;

import {
    NavigationActions,
    StackNavigator,
    addNavigationHelpers
} from 'react-navigation'
import {connect} from 'dva'
import TabBarTest from '../test/TabBarTest'
import ToolBar from '../../Components/ToolBar'
import emitter from '../../utils/SingleEventEmitter'

const createAction = type => payload => ({type,payload})
import {post,get} from '../../fetch'

const styles = StyleSheet.create({
    icon:{
        width:32,
        height:32
    },
})

const tabs = [
    { title: '热门比赛' },
    { title: '热门球队' },
    { title: '热门球员' },
];

@connect(({appNS,user,temp})=>({appNS,user,temp}))
class Main extends Component{
    static navigationOptions = {
        title:"首页",
        headerRight: <Image source={require('../../assets/images/sao.png')} style={{width:28,height:28,marginRight:10}}/>,
        headerStyle:{backgroundColor:"#0099FF"}
    }
    constructor(props){
        super(props);
        this.state = {
            chatlogin:false,
            username:'test',
            password:'123',
            friendname:'',
            modal1:false,
            drawerOpen:false,
        }
        this.drawer = null;
    }

    onDrawOpenChange = (isOpen) => {
        this.state.drawerOpen = isOpen;
    }

    gotoCount = ()=>{
        //this.props.navigation.navigate('Count')
        this.props.dispatch(NavigationActions.navigate({routeName:'Count'}))
    }
    gotoBTDiscover = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BTDiscover'}))
    }
    gotoBle = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BLEPage'}))
    }
    gotoBLEPeripheralTest = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BLEPeripheralTest'}))
    }
    gotobleP2PTest = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'bleP2PTest'}))
    }
    gotoCrossPlatformP2P=()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BluetoothCrossPlatform'}))
    }
    gotoReactArtTest = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'ReactArtTest'}))
    }
    gotoScanBar = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BarCodeTest'}))
    }
    gotoQrcode = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'QrCodeTest'}))
    }
    gotoQiniuLive = async()=>{
        if(Platform.OS == 'ios'){
            //this.props.dispatch(NavigationActions.navigate({routeName:'QiniuLiveTest'}))
            var result = await post("/getPublishURL",{streamname:"singlematch_roomid"})
            QiniuModule.Zhibo(result.url);
        }else{
            Toast.info("不支持android")
        }
    }
    gotoQiniuPlay = ()=>{
        if(Platform.OS == 'ios'){
            this.props.dispatch(NavigationActions.navigate({routeName:'QiniuPlayTest'}))
        }else{
            Toast.info("不支持android")
        }

    }
    gotoAgoraChatTest = ()=>{
        if(Platform.OS == 'ios'){
            this.props.dispatch(NavigationActions.navigate({routeName:'AgoraChatTest'}))
        }else{
            Toast.info("android暂时不支持")
        }

    }
    gotoAgoraChat_AndroidTest = ()=>{
        if(Platform.OS == 'ios'){
            Toast.info("不支持iOS")
        }else{
            this.props.dispatch(NavigationActions.navigate({routeName:'AgoraChat_AndroidTest'}))
        }
    }
    gotoShootTrainByVoice = ()=>
    {
        this.props.dispatch(NavigationActions.navigate({routeName:'ShootTrain'}))
    }
    gotoVoiceCount = ()=>{
        if(Platform.OS == 'ios'){
            this.props.dispatch(NavigationActions.navigate({routeName:'VoiceCount'}))
        }else{
            Toast.info("不支持android")
        }
    }
    gotoReactNativeCameraTest = ()=>{
        if(Platform.OS == 'ios'){
            this.props.dispatch(NavigationActions.navigate({routeName:'ReactNativeCameraTest'}))
        }else{
            Toast.info("不支持android")
        }
    }
    gotoLocalClient = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'LocalClientTest'}))
    }
    gotoLocalServer = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'LocalServerTest'}))
    }
    gotohighlightServer = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'highlightServer'}))
    }
    gotoCreateAp = async()=>{
            //this.props.dispatch(NavigationActions.navigate({routeName:'CreateWiFiAP'}))
            WiFiAPModule.openAPUI();
    }
    componentDidMount(){
        //this.props.dispatch(createAction('user/getUserInfo')({token:this.props.appNS.token}))
        //监听二维码扫码事件
        emitter.on("scanQRCode",(msg)=>{
            //Toast.info(msg);
            //return;
            var arr = msg.split('&');
            if(arr[0] == "highlightserver"){
                var ip = arr[1];
                Toast.info(ip);
                if(Platform.OS != 'ios')
                    QiniuModule.h264Record(this.props.appNS.clientID,0,"haimeng",10000,ip);
                else
                    QiniuModule.gotoCameraOnStand(this.props.appNS.clientID,0,"haimeng",10000,ip);
                return;
            }else if(arr[0] == "playrtmpurl"){
                //Toast.info(arr[1]);
                setTimeout(()=>{
                    this.props.dispatch(NavigationActions.navigate({
                        routeName:'QiniuPlayTest',
                        params: {
                            url:arr[1]
                        },
                    }))
                },0)
            }
        })
    }

    easeChatRegister = async () => {
        try{
            var result = await ChatModule.register(this.state.username,this.state.password,"")
            Toast.info(result);
        }catch(e){
            console.error(e);
        }
    }

    easeChatLogin = async () => {
        try{
            var result = await ChatModule.login(this.state.username,this.state.password);
            this.setState({chatlogin:true});
        }catch(e){
            console.error(e);
        }
    }

    easeChatLogout = async() => {
        try{
            var result = await ChatModule.logout();
            this.setState({chatlogin:false})
        }catch(e){
            console.error(e);
        }
    }

    chatWithFriends = () =>{
        if(this.state.friendname.length > 0)
            ChatModule.chatWithFriends(this.state.friendname)
        else
            Toast.info("好友账号不能为空")
    }

    render(){
        const sidebar = (<List>

            <List.Item key={1}

            >
                <TouchableHighlight onPress={()=>{
                    this.gotoScanBar();
                }}>
                <View style={{flexDirection:'row',alignItems:'center'}}>
                <Image source={require('../../assets/images/sao.png')} style={{width:28,height:28,marginRight:10}}/>
                <Text>扫一扫</Text>
            </View>
                </TouchableHighlight>
            </List.Item>

            <List.Item key={2}
            >
                <TouchableHighlight onPress={()=>{
                    WiFiAPModule.openWifiSetting();
                }}>
                <View style={{flexDirection:'row',alignItems:'center'}}>
                <Image source={require('../../assets/images/qrcode.png')} style={{width:28,height:28,marginRight:10}}/>
                <Text>连接热点</Text>
            </View>
                </TouchableHighlight>
            </List.Item>
            <List.Item key={3}
            >
                <TouchableHighlight onPress={()=>{
                    this.gotoCreateAp();
                }}>
                <View style={{flexDirection:'row',alignItems:'center'}}>
                    <Image source={require('../../assets/images/wi-fi.png')} style={{width:28,height:28,marginRight:10}}/>
                    <Text>设置Wi-Fi热点</Text>
            </View>
                </TouchableHighlight>
            </List.Item>
        </List>);

        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="首页"
                    headerLeft={<Image source={require('../../assets/images/qrcode.png')} style={{width:28,height:28}}/>}
                    navigation={this.props.navigation}
                    headerRight={
                        <Badge text={9}>
                        <TouchableHighlight onPress={() => {
                            if(this.drawer){
                                if(this.state.drawerOpen){
                                    this.drawer.closeDrawer();
                                }else{
                                    this.drawer.openDrawer();
                                }
                            }
                        }}>
                        <Image source={require('../../assets/images/add.png')} style={{width:28,height:28}}/>
                        </TouchableHighlight>
                        </Badge>
                    } />
                <Drawer
                    sidebar={sidebar}
                    position="right"
                    open={false}
                    drawerRef={(el) => this.drawer = el}
                    onOpenChange={this.onDrawOpenChange}
                    drawerBackgroundColor="#ccc"
                >
                    {this.props.temp.isOffline?<NoticeBar mode="" onClick={()=>{Toast.info("重连服务器...")}} icon={null}>离线模式(点击重连)</NoticeBar>:null}
                <Tabs
                    tabs={tabs}
                    initialPage={0}
                >
                    <View style={{flex:1}}>
                        <ScrollView style={{flex:1}}>
                                <WhiteSpace/>
                                <WingBlank>
                                    <View>
                                        <Button onClick={()=>this.setState({modal1:true})}>对话框</Button>
                                        <Modal
                                            title="这是 title"
                                            transparent
                                            maskClosable={true}
                                            visible={this.state.modal1}
                                            onClose={()=>this.setState({modal1:false})}
                                            footer={[{ text: '确定', onPress: () => {  this.setState({modal1:false}) } }]}
                                        >
                                            <Text>这是内容...</Text>
                                            <Text>这是内容...</Text>
                                        </Modal>
                                    </View>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoCount}>地理定位</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoBTDiscover}>Android 经典蓝牙和Wi-Fi Direct</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoBle}>ble-manager(中心设备)</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoBLEPeripheralTest}>BLE外围设备</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotobleP2PTest}>基于BLE的P2P系统</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoCrossPlatformP2P}>bluetooth-cross-platform</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoReactArtTest}>ReactArt测试</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoScanBar}>扫一扫</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoQrcode}>二维码</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoQiniuLive}>七牛直播</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoQiniuPlay}>七牛观看</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoAgoraChatTest}>单项技巧视频赛事中控端</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoAgoraChat_AndroidTest}>单项技巧视频赛事云端</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoShootTrainByVoice}>智能投篮训练</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoVoiceCount}>语音计数</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoReactNativeCameraTest}>短视频录制和后期处理</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoLocalClient}>热点客户端</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotoLocalServer}>热点服务器</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.gotohighlightServer}>集锦服务器</Button>
                                </WingBlank>

                                <WhiteSpace size="lg"/>
                                <WingBlank>
                                    <Card>
                                        <Card.Header
                                            title="聊天"
                                            thumb="https://www.easemob.com/themes/official_v3/Public/img/logo.png"

                                        />
                                        <Card.Body style={{backgroundColor:'#ccc'}}>
                                            <WingBlank>
                                                {
                                                    this.state.chatlogin?
                                                        <List>
                                                            <InputItem
                                                                labelNumber="5"
                                                                value={this.state.friendname}
                                                                onChange={value=>this.setState({friendname:value})}
                                                            >好友账号：</InputItem>
                                                            <Button
                                                                onClick={this.chatWithFriends}
                                                            >聊天</Button>
                                                            <Button
                                                                onClick={this.easeChatLogout}
                                                            >注销</Button>
                                                        </List>
                                                        :
                                                        <List>
                                                            <InputItem
                                                                value={this.state.username}
                                                                onChange={value=>this.setState({username:value})}
                                                            >用户名：</InputItem>
                                                            <InputItem
                                                                value={this.state.password}
                                                                onChange={value=>this.setState({password:value})}
                                                            >密码：</InputItem>
                                                            <Button
                                                                onClick={this.easeChatRegister}
                                                            >注册</Button>
                                                            <Button
                                                                onClick={this.easeChatLogin}
                                                            >登陆</Button>
                                                        </List>
                                                }
                                            </WingBlank>
                                        </Card.Body>
                                        <Card.Footer content="" />
                                    </Card>
                                </WingBlank>
                            </ScrollView>
                    </View>
                    <View style={{flex:1}}>
                        <Text>
                            Content of First Tab
                        </Text>
                    </View>
                    <View style={{flex:1}}>
                        <Text>
                            Content of Third Tab
                        </Text>
                    </View>
                </Tabs>
                </Drawer>
            </View>
        )
    }
}

var MainNavigator = StackNavigator(
    {
        Main:{screen:Main},
        TabBarTest:{screen:TabBarTest}
    },
    {
        headerMode:'none'
    }
)

export default class Tab1Page extends Component{
    constructor(props){
        super(props);
        this.state = {
            newinfonum:1
        }
    }
    static navigationOptions = {
        tabBarLabel:'首页',
        tabBarIcon: ({ focused, tintColor }) =>
            <View>
                <Image
                    style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                    source={require('../../assets/images/house.png')}
                />
            </View>
            ,
    }

    render(){
        return (
            <Main navigation={this.props.navigation} />
        )
    }
}

