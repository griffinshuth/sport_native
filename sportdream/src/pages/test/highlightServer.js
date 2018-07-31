import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    requireNativeComponent,
    Platform,
    ScrollView,
    TouchableHighlight,
    Image
} from 'react-native'
import {
    Toast,
    Button,
    WhiteSpace,
    ActionSheet,
    Accordion,
    Grid,
    Tag,
    List,
    Picker,
    Switch,
    Flex,
    Modal,
    Card
} from 'antd-mobile'
import {CameraStandView,HighlightServerModule,HighlightServerModuleEmitter} from '../NativeModules/HighlightModule'

var LocalClientModule = NativeModules.LocalClientModule;
const LocalClientModuleEmitter = new NativeEventEmitter(LocalClientModule);

import { NetworkInfo } from 'react-native-network-info';


import ToolBar from '../../Components/ToolBar'
import JSONPacketStruct from "../../utils/JSONPacketStruct";

const BUTTONS = [
    {label:'一个I帧',value:1},
    {label:'5秒',value:2},
    {label:'10秒',value:4},
    {label:'20秒',value:8},
    {label:'30秒',value:15},
    {label:'一分钟',value:30},
    {label:'5分钟',value:150},
    {label:'10分钟',value:300},
    {label:'20分钟',value:600},
    ];

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            isDirectServerConnected:false,
            cameras:[],  //每个机位的deviceID
            chooseCameraLabel:"选择机位",
            chooseCameraDeviceID:null,
            flashBack:[],  //{deviceId:"",beginFrame:null,endFrame:null}
            highlights:[], //{deviceId:"",beginFrame:null,endFrame:null}
            isFlashback:true,
            seekIntervalLabel:"一个I帧",
            seekIntervalValue:1,
        }
        this.internal = {
            currentPlaybackFrame:null,
        }
    }

    createCamera = (deviceId,type,name,isSlowMotion) => {
        return {
            deviceId:deviceId,
            type:type,
            name:name,
            isSlowMotion:isSlowMotion,
            isWatchRealTimePicture:false,
            isPlayBacking:false,
            currentFrame:null,
            beginFrame:null,  //将要截取的片段的开始帧
        }
    }

    createVideoFrame = (frame)=>{
        return {
            type:frame.type,
            absoluteTime:frame.absoluteTime,
            relativeTime:frame.relativeTime,
            frameIndex:frame.frameIndex,
            IFrameIndex:frame.IFrameIndex,
            position:frame.position,
            length:frame.length,
            duration:frame.duration
        }
    }

    getCameraByDeviceID = (deviceId)=>{
        for(var i=0;i<this.state.cameras.length;i++){
            if(this.state.cameras[i].deviceId == deviceId){
                return this.state.cameras[i];
            }
        }
        return null;
    }
    componentDidMount(){
        if(Platform.OS == 'android'){
            Toast.info(Platform.OS);
            //服务器
            NetworkInfo.getIPAddress(ipv4 => {
                HighlightServerModule.startServer(ipv4,4002);
            });
            this.onHighlightServerListening_handler = HighlightServerModuleEmitter.addListener("onHighlightServerListening",this.onHighlightServerListening);
            this.onHighlightServerRemoteClientLogined_handler = HighlightServerModuleEmitter.addListener("onHighlightServerRemoteClientLogined",this.onHighlightServerRemoteClientLogined);
            this.onHighlightServerRemoteClientClosed_handler = HighlightServerModuleEmitter.addListener("onHighlightServerRemoteClientClosed",this.onHighlightServerRemoteClientClosed);
            this.onHighlightServerClosed_handler = HighlightServerModuleEmitter.addListener("onHighlightServerClosed",this.onHighlightServerClosed);
            this.onHighlightServerDataReceived_handler = HighlightServerModuleEmitter.addListener("onHighlightServerDataReceived",this.onHighlightServerDataReceived);
        }else{
            //服务器
            HighlightServerModule.startServer(5002,4002);
            this.onHighlightServerRemoteClientLogined_handler = NativeAppEventEmitter.addListener("onHighlightServerRemoteClientLogined",this.onHighlightServerRemoteClientLogined);
            this.onHighlightServerRemoteClientClosed_handler = NativeAppEventEmitter.addListener("onHighlightServerRemoteClientClosed",this.onHighlightServerRemoteClientClosed);
            this.onHighlightServerDataReceived_handler = NativeAppEventEmitter.addListener("onHighlightServerDataReceived",this.onHighlightServerDataReceived);
        }


        //客户端
        this.serverDiscovered_handler = LocalClientModuleEmitter.addListener("serverDiscovered",this.serverDiscovered);
        this.clientReceiveData_handler = LocalClientModuleEmitter.addListener("clientReceiveData",this.clientReceiveData);
        this.clientSocketConnected_handler = LocalClientModuleEmitter.addListener("clientSocketConnected",this.clientSocketConnected);
        this.clientSocketDisconnect_handler = LocalClientModuleEmitter.addListener("clientSocketDisconnect",this.clientSocketDisconnect);
        LocalClientModule.startClient(8888,6666);
    }

    componentWillUnmount(){
        if(Platform.OS == 'android'){
            //服务器
            HighlightServerModule.stopServer();
            this.onHighlightServerListening_handler.remove();
            this.onHighlightServerRemoteClientLogined_handler.remove();
            this.onHighlightServerRemoteClientClosed_handler.remove();
            this.onHighlightServerClosed_handler.remove();
            this.onHighlightServerDataReceived_handler.remove();
        }else{
            //服务器
            HighlightServerModule.stopServer();
            this.onHighlightServerRemoteClientLogined_handler.remove();
            this.onHighlightServerRemoteClientClosed_handler.remove();
            this.onHighlightServerDataReceived_handler.remove();
        }


        //客户端
        this.serverDiscovered_handler.remove();
        this.clientReceiveData_handler.remove();
        this.clientSocketConnected_handler.remove();
        this.clientSocketDisconnect_handler.remove();
        LocalClientModule.stopClient();
    }

    //连接导播服务器的网络客户端begin
    search = ()=>{
        if(!this.state.isDirectServerConnected){
            LocalClientModule.searchServer();
        }else{
            if(this.state.isFlashback){
                Modal.alert('回放', '确定要发送精彩回放吗', [
                    { text: '取消', onPress: () => console.log('cancel') },
                    { text: '确定', onPress: () => {
                        if(this.state.flashBack.length == 0){
                            Toast.info("精彩回放为空",1);
                            return;
                        }
                        this.sendToDirectServer({id:"flashBackList",sections:this.state.flashBack});
                    } },
                ])
            }else{
                Modal.prompt('集锦', '请输入集锦标题', [
                    { text: '取消' },
                    { text: '提交', onPress: value =>{
                        if(value == ""){
                            Toast.info("标题不能为空",1);
                            return;
                        }
                        if(this.state.highlights.length == 0){
                            Toast.info("集锦不能为空",1);
                            return;
                        }
                        this.sendToDirectServer({id:"highlightList",sections:this.state.highlights,name:value});
                    } },
                ], 'default', '')
            }

        }
    }
    sendToDirectServer = (json)=>{
        var str = JSON.stringify(json);
        LocalClientModule.clientSend(str);
    }
    serverDiscovered = ()=>{
        Toast.info("server discovered")
    }
    clientReceiveData = (result)=>{
        Toast.info(result);
    }
    clientSocketConnected = ()=>{
        var clientID = this.props.appNS.clientID;
        var json = JSONPacketStruct.highlightsLogin(clientID);
        this.sendToDirectServer(json);
        this.setState({isDirectServerConnected:true})
    }
    clientSocketDisconnect = ()=>{
        this.setState({isDirectServerConnected:false})
    }

    //连接导播服务器的网络客户端end


    onHighlightServerListening = ()=>{
        Toast.info("server listening",1)
    }

    onHighlightServerRemoteClientLogined = (result)=>{
        var deviceID = result.deviceID;
        var type = result.type;
        var name = result.name;
        var isSlowMotion = result.isSlowMotion;
        var obj = this.createCamera(deviceID,type,name,isSlowMotion);
        this.setState({cameras:[...this.state.cameras,obj]});
    }

    onHighlightServerRemoteClientClosed = (result)=>{
        var deviceID = result.deviceID;
        if(deviceID == this.state.chooseCameraDeviceID){
            this.setState({chooseCameraDeviceID:"",chooseCameraLabel:"选择机位"})
        }
        this.setState({cameras:this.state.cameras.filter((item,index)=>{
            if(item.deviceId != deviceID){
                return true;
            }else{
                return false;
            }
        })})
    }

    onHighlightServerClosed = ()=>{

    }

    onHighlightServerDataReceived = (result)=>{
        var deviceID = result.deviceID;
        var json_str = result.json_str;
        var json = JSON.parse(json_str);
        if(json.id == "getNewestSmallIFrame"){
            var currentMetaData = this.createVideoFrame(json);
            this.setState({cameras:this.state.cameras.map((item,index)=>{
                if(item.deviceId == deviceID){
                    return {...item,currentFrame:currentMetaData}
                }else{
                    return item;
                }
            })})
        }else if(json.id == "getNextSmallFrame"){
            var currentMetaData = this.createVideoFrame(json);
            var camera = this.getCameraByDeviceID(deviceID);
            this.internal.currentPlaybackFrame = currentMetaData;
            if(camera.isPlayBacking){
                var duration = currentMetaData.duration;
                duration -= 10;
                if(duration<30){
                    duration = 30;
                }

                setTimeout(()=>{
                    var frameIndex = currentMetaData.frameIndex;
                    var getNextSmallFrame_json = JSONPacketStruct.getNextSmallFrame(frameIndex);
                    HighlightServerModule.send(deviceID,JSON.stringify(getNextSmallFrame_json));
                },duration)
            }
        }else if(json.id == "seekFrontIFrame"){
            var currentMetaData = this.createVideoFrame(json);
            this.setState({cameras:this.state.cameras.map((item,index)=>{
                if(item.deviceId == deviceID){
                    return {...item,currentFrame:currentMetaData}
                }else{
                    return item;
                }
            })})
        }else if(json.id == "seekBackIFrame"){
            var currentMetaData = this.createVideoFrame(json);
            this.setState({cameras:this.state.cameras.map((item,index)=>{
                if(item.deviceId == deviceID){
                    return {...item,currentFrame:currentMetaData}
                }else{
                    return item;
                }
            })})
        }

    }

    startLive = (deviceID)=>{
        var camera = this.getCameraByDeviceID(deviceID);
        if(camera){
            var json = JSONPacketStruct.highlight_startplay(!camera.isWatchRealTimePicture);
            HighlightServerModule.send(deviceID,JSON.stringify(json));
            this.setState({cameras:this.state.cameras.map((item,index)=>{
                if(item == camera){
                    return {...item,isWatchRealTimePicture:!camera.isWatchRealTimePicture}
                }else{
                    return item;
                }
            })})
        }
    }

    beginMakeHighlights = (deviceId)=>{
        var camera = this.getCameraByDeviceID(deviceId);
        if(camera){
            var getNewestIFrame_json = JSONPacketStruct.getNewestSmallIFrame();
            HighlightServerModule.send(deviceId,JSON.stringify(getNewestIFrame_json));
        }
    }

    seekback = (deviceId)=>{
        var camera = this.getCameraByDeviceID(deviceId);
        if(camera && camera.currentFrame){
            var frameIndex = camera.currentFrame.frameIndex;
            var interval = this.state.seekIntervalValue;
            var seekBackIFrame_json = JSONPacketStruct.seekBackIFrame(frameIndex,interval);
            HighlightServerModule.send(deviceId,JSON.stringify(seekBackIFrame_json));
        }
    }
    seekfront = (deviceId)=>{
        var camera = this.getCameraByDeviceID(deviceId);
        if(camera && camera.currentFrame){
            var frameIndex = camera.currentFrame.frameIndex;
            var interval = this.state.seekIntervalValue;
            var seekFrontIFrame_json = JSONPacketStruct.seekFrontIFrame(frameIndex,interval);
            HighlightServerModule.send(deviceId,JSON.stringify(seekFrontIFrame_json));
        }
    }
    startplayback = (deviceId)=>{
        var camera = this.getCameraByDeviceID(deviceId);
        if(camera && camera.currentFrame){
            if(!camera.isPlayBacking){
                var frameIndex = camera.currentFrame.frameIndex;
                var duration = camera.currentFrame.duration;
                var getNextSmallFrame_json = JSONPacketStruct.getNextSmallFrame(frameIndex);
                HighlightServerModule.send(deviceId,JSON.stringify(getNextSmallFrame_json));
                this.setState({cameras:this.state.cameras.map((item,index)=>{
                    if(item == camera){
                        return {...item,isPlayBacking:!camera.isPlayBacking}
                    }else{
                        return item;
                    }
                })})
            }else{
                this.setState({cameras:this.state.cameras.map((item,index)=>{
                    if(item == camera){
                        return {...item,isPlayBacking:!camera.isPlayBacking,currentFrame:this.internal.currentPlaybackFrame}
                    }else{
                        return item;
                    }
                })})
                this.internal.currentPlaybackFrame = null;
            }
        }

    }
    setBeginFrame = (deviceId)=>{
        var camera = this.getCameraByDeviceID(deviceId);
        if(camera){
            if(camera.currentFrame == null){
                Toast.info("当前帧为空",1);
                return;
            }
            if(camera.currentFrame.type != 3){
                Toast.info("开始帧必须是I帧")
                return;
            }
            this.setState({cameras:this.state.cameras.map((item,index)=>{
                if(item.deviceId == deviceId){
                    return {...item,beginFrame:camera.currentFrame}
                }else{
                    return item;
                }
            })})
        }
    }
    cutout = (deviceId)=>{
        var camera = this.getCameraByDeviceID(deviceId);
        if(camera){
            var begin = camera.beginFrame;
            if(begin == null){
                Toast.info("没有指定开始帧",1);
                return;
            }
            var end = null;
            if(!camera.isPlayBacking){
                end = camera.currentFrame;
            }else{
                end = this.internal.currentPlaybackFrame;
            }

            if(end == null){
                Toast.info("结束帧为空",1);
                return
            }

            if(begin.frameIndex == end.frameIndex){
                Toast.info("开始帧和结束帧不能相等",1);
                return;
            }
            if(begin.frameIndex > end.frameIndex){
                //交换
                let tempframe = begin;
                begin = end;
                end = tempframe;
            }

            if(camera.isPlayBacking){
                //停止回放
                this.setState({cameras:this.state.cameras.map((item,index)=>{
                    if(item == camera){
                        return {...item,isPlayBacking:!camera.isPlayBacking,currentFrame:this.internal.currentPlaybackFrame,beginFrame:null}
                    }else{
                        return item;
                    }
                })})
                this.internal.currentPlaybackFrame = null;
            }else{
                //清空开始帧
                this.setState({cameras:this.state.cameras.map((item,index)=>{
                    if(item == camera){
                        return {...item,beginFrame:null}
                    }else{
                        return item;
                    }
                })})
            }

            //生成视频片段
            var chooseCamera = this.getCameraByDeviceID(this.state.chooseCameraDeviceID);
            var framesLength = end.frameIndex - begin.frameIndex;
            var section = {deviceId:deviceId,isSlowMotion:chooseCamera.isSlowMotion,beginAbsoluteTimestamp:begin.absoluteTime,framesLength:framesLength}
            if(this.state.isFlashback){
                this.setState({flashBack:[...this.state.flashBack,section]});
            }else{
                this.setState({highlights:[...this.state.highlights,section]});
            }
        }
    }
    playcutout = (deviceId,index)=>{

    }
    deletecutout = (deviceId,index) =>{

    }
    render(){
        var picker_data = [];
        for(var i=0;i<this.state.cameras.length;i++){
            picker_data.push({label:"机位"+(i+1),value:this.state.cameras[i].deviceId})
        }
        var currentFrame = null;
        var beginFrame = null;
        for(var i=0;i<this.state.cameras.length;i++){
            if(this.state.chooseCameraDeviceID == this.state.cameras[i].deviceId){
                currentFrame = this.state.cameras[i].currentFrame;
                beginFrame = this.state.cameras[i].beginFrame;
            }
        }
        return (
            <View style={{flex:1}}>
                <ToolBar title="集锦服务器" navigation={this.props.navigation}
                         headerRight={<TouchableHighlight onPress={() => {
                             NetworkInfo.getIPAddress(ipv4 => {
                                 //Toast.info(ipv4);
                                 this.props.navigation.navigate("QrCodeTest",{page:"highlightserver",param:ipv4})
                             });
                         }}>
                             <Image source={require('../../assets/images/qrcode.png')} style={{width:28,height:28}}/>
                         </TouchableHighlight>}
                />
                    <ScrollView style={{marginLeft:10,marginRight:10}}>
                        <WhiteSpace/>
                        <View style={{alignItems:'center'}}>
                            <CameraStandView IsHighlight={true} style={{width:320,height:180,borderWidth:1,borderColor:'red'}} />
                        </View>

                        <List>
                            <List.Item>
                                <Button type="primary" inline onClick={this.search}>{!this.state.isDirectServerConnected?"点击连接导播服务器":"发送精彩回放或集锦"}</Button>
                            </List.Item>
                            <Picker onOk={(val)=>{
                                var deviceId = val+"";
                                for(var i=0;i<picker_data.length;i++){
                                    if(this.state.chooseCameraDeviceID != null){
                                        //清空开始帧
                                        this.setState({cameras:this.state.cameras.map((item,index)=>{
                                            if(item.deviceId == this.state.chooseCameraDeviceID){
                                                return {...item,beginFrame:null,currentFrame:null,isPlayBacking:false}
                                            }else{
                                                return item;
                                            }
                                        })})
                                    }
                                    if(picker_data[i].value == val){
                                        this.setState({chooseCameraDeviceID:deviceId,chooseCameraLabel:"机位"+(i+1)})
                                        break;
                                    }
                                }
                            }} data={picker_data} cols={1}>
                                <List.Item arrow="horizontal">{this.state.chooseCameraLabel}</List.Item>
                            </Picker>
                            <Picker onOk={(val)=>{
                                var val = parseInt(val);
                                Toast.info(val,1);
                                this.setState({seekIntervalValue:val})
                                for(var i=0;i<BUTTONS.length;i++){
                                    if(BUTTONS[i].value == val){
                                        this.setState({seekIntervalLabel:BUTTONS[i].label})
                                        break;
                                    }
                                }
                            }}  data={BUTTONS} cols={1}  extra="选择时间间隔">
                                <List.Item arrow="horizontal">{this.state.seekIntervalLabel}</List.Item>
                            </Picker>
                            <List.Item
                                extra={<Switch
                                    checked={this.state.isFlashback}
                                    onChange={(checked) => { this.setState({isFlashback:checked}); }}
                                />}
                            >{this.state.isFlashback?"精彩回放":"集锦"}</List.Item>
                        </List>
                        <List>
                            <List.Item
                                multipleLine
                                extra={currentFrame?currentFrame.frameIndex:null}
                            >
                                当前帧<List.Item.Brief>{currentFrame?new Date(currentFrame.absoluteTime).toLocaleTimeString():"不存在"}</List.Item.Brief>
                            </List.Item>
                        </List>
                        <List>
                            <List.Item
                                multipleLine
                                extra={beginFrame?beginFrame.frameIndex:null}
                            >
                                开始帧<List.Item.Brief>{beginFrame?new Date(beginFrame.absoluteTime).toLocaleTimeString():"不存在"}</List.Item.Brief>
                            </List.Item>
                        </List>
                        <View>
                            <Flex>
                                <Flex.Item><Button onClick={()=>{
                                    if(this.state.chooseCameraDeviceID == null){
                                        Toast.info("没有选择机位",1)
                                        return;
                                    }
                                    var deviceid = this.state.chooseCameraDeviceID;
                                    this.beginMakeHighlights(deviceid)
                                }}>初始时间点</Button></Flex.Item>
                                <Flex.Item><Button onClick={()=>{
                                    if(this.state.chooseCameraDeviceID == null){
                                        Toast.info("没有选择机位",1)
                                        return;
                                    }
                                    var deviceid = this.state.chooseCameraDeviceID;
                                    this.startplayback(deviceid);
                                }}>回放</Button></Flex.Item>
                            </Flex>
                            <Flex>
                                <Flex.Item><Button onClick={()=>{
                                    if(this.state.chooseCameraDeviceID == null){
                                        Toast.info("没有选择机位",1)
                                        return;
                                    }
                                    var deviceid = this.state.chooseCameraDeviceID;
                                    this.seekfront(deviceid);
                                }}>倒带</Button></Flex.Item>
                                <Flex.Item><Button onClick={()=>{
                                    if(this.state.chooseCameraDeviceID == null){
                                        Toast.info("没有选择机位",1)
                                        return;
                                    }
                                    var deviceid = this.state.chooseCameraDeviceID;
                                    this.seekback(deviceid);
                                }}>快进</Button></Flex.Item>
                            </Flex>
                            <Flex>
                                <Flex.Item><Button onClick={()=>{
                                    if(this.state.chooseCameraDeviceID == null){
                                        Toast.info("没有选择机位",1)
                                        return;
                                    }
                                    var deviceid = this.state.chooseCameraDeviceID;
                                    this.setBeginFrame(deviceid);
                                }}>开始片段</Button></Flex.Item>
                                <Flex.Item><Button onClick={()=>{
                                    if(this.state.chooseCameraDeviceID == null){
                                        Toast.info("没有选择机位",1)
                                        return;
                                    }
                                    var deviceid = this.state.chooseCameraDeviceID;
                                    this.cutout(deviceid);
                                }}>截取片段</Button></Flex.Item>
                            </Flex>
                        </View>
                        <WhiteSpace/>
                        <Card>
                            <Card.Header
                                title="回放或集锦片段列表"
                                extra={"片段数量"}
                            />
                            <Card.Body>
                                <List>
                                    {
                                        this.state.isFlashback?this.state.flashBack.map((item,index)=>{
                                            return <List.Item onClick={()=>{
                                                Modal.operation([
                                                    { text: '删除', onPress: () => console.log('标为未读被点击了') },
                                                    { text: '播放', onPress: () => console.log('置顶聊天被点击了') },
                                                    { text: '上移', onPress: () => console.log('标为未读被点击了') },
                                                    { text: '下移', onPress: () => console.log('置顶聊天被点击了') },
                                                ])
                                            }} key={index} extra={'时长'}>片段</List.Item>
                                        }):this.state.highlights.map((item,index)=>{
                                            return <List.Item onClick={()=>{
                                                Modal.operation([
                                                    { text: '删除', onPress: () => console.log('标为未读被点击了') },
                                                    { text: '播放', onPress: () => console.log('置顶聊天被点击了') },
                                                    { text: '上移', onPress: () => console.log('标为未读被点击了') },
                                                    { text: '下移', onPress: () => console.log('置顶聊天被点击了') },
                                                ])
                                            }} key={index} extra={'时长'}>片段</List.Item>
                                        })
                                    }
                                </List>
                            </Card.Body>
                        </Card>
                        <WhiteSpace/>
                    </ScrollView>
            </View>
        )
    }
}