import React from 'react'
import {
    StyleSheet,
    View,
    Text,
    requireNativeComponent,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    DeviceEventEmitter,
    Platform,
    Dimensions,
    PermissionsAndroid
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast,
    Flex
} from 'antd-mobile'
import Orientation from 'react-native-orientation';
import AgorachatNativeView from '../../NativeViews/AgorachatView'
import {get, post,serverurl} from '../../fetch'
import io from 'socket.io-client'
import {clientEvent,serverEvent} from '../../utils/socketEvent'

var BaiduASRModule = NativeModules.BaiduASRModule;
import BleManager from 'react-native-ble-manager';
const BleManagerModule = NativeModules.BleManager;
const bleManagerEmitter = new NativeEventEmitter(BleManagerModule);

//智能篮球架uuid
var service = "FFE0";
var characteristic = "FFE1";

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
            status:0,
            channel:"test",
            players : [],
            isPushing:false,
            isEnterMatch:false,
            currentTime:0,
            //ble
            scanning:false,
            peripherals: new Map(),
            connectedPeripheralId:null,
        }

    }

    componentWillMount(){
        BaiduASRModule.initTTS();
    }

    componentDidMount(){
        this.setState({status:1})
        Orientation.lockToLandscape();

        this.onUserOffline = DeviceEventEmitter.addListener('onUserOffline', (data) => {
            // handle event.
            var index = this.state.players.indexOf(data.uid);
            if(index>=0){
                this.state.players.splice(index,1);
                this.setState({players:this.state.players})
            }
        });
        this.onUserJoined = DeviceEventEmitter.addListener('onUserJoined', (data)=> {
            // handle event.
            this.state.players.push(data.uid);
            this.setState({players:this.state.players})
        });
        this.onLeaveChannel = DeviceEventEmitter.addListener('onLeaveChannel', (data)=> {
            // handle event.
            this.props.navigation.goBack();
        });

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

        //低功耗蓝牙相关
        this.handlerDiscover = bleManagerEmitter.addListener('BleManagerDiscoverPeripheral', this.handleDiscoverPeripheral );
        this.handlerStop = bleManagerEmitter.addListener('BleManagerStopScan', this.handleStopScan );
        this.handlerDisconnect = bleManagerEmitter.addListener('BleManagerDisconnectPeripheral', this.handleDisconnectedPeripheral );
        this.handlerUpdate = bleManagerEmitter.addListener('BleManagerDidUpdateValueForCharacteristic', this.handleUpdateValueForCharacteristic );

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
    }

    componentWillUnmount(){
        Orientation.lockToPortrait();
        BaiduASRModule.destroyTTS();
        this.onUserOffline.remove();
        this.onUserJoined.remove();
        this.onLeaveChannel.remove();

        this.socket.disconnect();

        this.handlerDiscover.remove();
        this.handlerStop.remove();
        this.handlerDisconnect.remove();
        this.handlerUpdate.remove();

        const list = Array.from(this.state.peripherals.values());
        for(var i=0;i<list.length;i++){
            BleManager.disconnect(list[i].id);
        }
    }

    speak = (word)=>{
        BaiduASRModule.speak(word);
    }

    handleDisconnectedPeripheral = (data) => {
        let peripherals = this.state.peripherals;
        let peripheral = peripherals.get(data.peripheral);
        if (peripheral) {
            peripheral.connected = false;
            peripherals.set(peripheral.id, peripheral);
            this.setState({peripherals,connectedPeripheralId:null});
            this.startScan();
        }
    }

    bytesToStringcustom(arr) {
        if(typeof arr === 'string') {
            return arr;
        }
        var str = '',
            _arr = arr;
        for(var i = 0; i < _arr.length; i++) {
            var one = _arr[i].toString(2),
                v = one.match(/^1+?(?=0)/);
            if(v && one.length == 8) {
                var bytesLength = v[0].length;
                var store = _arr[i].toString(2).slice(7 - bytesLength);
                for(var st = 1; st < bytesLength; st++) {
                    store += _arr[st + i].toString(2).slice(2);
                }
                str += String.fromCharCode(parseInt(store, 2));
                i += bytesLength - 1;
            } else {
                str += String.fromCharCode(_arr[i]);
            }
        }
        return str;
    }

    stringToBytecustom(str) {
        var bytes = new Array();
        var len, c;
        len = str.length;
        for(var i = 0; i < len; i++) {
            c = str.charCodeAt(i);
            if(c >= 0x010000 && c <= 0x10FFFF) {
                bytes.push(((c >> 18) & 0x07) | 0xF0);
                bytes.push(((c >> 12) & 0x3F) | 0x80);
                bytes.push(((c >> 6) & 0x3F) | 0x80);
                bytes.push((c & 0x3F) | 0x80);
            } else if(c >= 0x000800 && c <= 0x00FFFF) {
                bytes.push(((c >> 12) & 0x0F) | 0xE0);
                bytes.push(((c >> 6) & 0x3F) | 0x80);
                bytes.push((c & 0x3F) | 0x80);
            } else if(c >= 0x000080 && c <= 0x0007FF) {
                bytes.push(((c >> 6) & 0x1F) | 0xC0);
                bytes.push((c & 0x3F) | 0x80);
            } else {
                bytes.push(c & 0xFF);
            }
        }
        return bytes;


    }

    handleUpdateValueForCharacteristic = (data) => {
        //智能篮球架协议解析
        var result = this.bytesToStringcustom(data.value);
        if(result == "started"){
            BaiduASRModule.speak("go")
        }else if(result == "p"){
            //Toast.info("命中",1);
            this.socket.emit(serverEvent.ShootMatchUpdateScore,{},(data)=>{
                if(data.error){
                    Toast.info(data.error);
                }else{
                    AgorachatModule.setMatchScores(this.state.myscore+1,this.state.otherscore);
                    this.setState({myscore:this.state.myscore+1})
                }
            })
        }else if(result == "down:tosmall"){
            BaiduASRModule.speak("下面舵机达到最小角度")
        }else if(result == "down:tobig"){
            BaiduASRModule.speak("下面舵机达到最大角度")
        }else if(result == "up:tosmall"){
            BaiduASRModule.speak("上面舵机达到最小角度")
        }else if(result == "up:tobig"){
            BaiduASRModule.speak("上面舵机达到最大角度")
        }else{
            var arr = result.split('-');
            if(arr.length == 2){
                if(arr[0] == "down:info"){
                    BaiduASRModule.speak("下面舵机的角度是"+arr[1]+"度");
                }else if(arr[0] == "up:info"){
                    BaiduASRModule.speak("上面舵机的角度是"+arr[1]+"度");
                }
            }
        }
    }

    handleStopScan = () => {
        console.log('Scan is stopped');
        this.setState({ scanning: false });
        Toast.hide();
    }

    reset = ()=>{
        const list = Array.from(this.state.peripherals.values());
        for(var i=0;i<list.length;i++){
            BleManager.disconnect(list[i].id);
        }
        this.setState({peripherals:new Map()})
    }

    startScan = () => {
        if (!this.state.scanning) {
            this.reset();
            BleManager.scan([], 3, true).then((results) => {
                console.log('Scanning...');
                this.setState({scanning:true});
                Toast.info("扫描中。。。",0)
            });
        }
    }

    handleDiscoverPeripheral = (peripheral) => {
        var peripherals = this.state.peripherals;
        if(peripheral.name != "BT05-A"){
            return;
        }

        if (!peripherals.has(peripheral.id)){
            peripherals.set(peripheral.id, peripheral);
            this.setState({ peripherals })
            //连接设备
            this.connectDevice(peripheral);
        }
    }

    connectDevice = (peripheral) => {
        if(peripheral){
            if (peripheral.connected){
                //BleManager.disconnect(peripheral.id);
                Toast.info("篮球架已经连接，不能重复连接")
            }else{
                BleManager.connect(peripheral.id).then(()=>{
                    let peripherals = this.state.peripherals;
                    let p = peripherals.get(peripheral.id);
                    if (p) {
                        p.connected = true;
                        peripherals.set(peripheral.id, p);
                        this.setState({peripherals});
                    }

                    BleManager.retrieveServices(peripheral.id).then((peripheralInfo) => {
                        console.log(peripheralInfo);
                        BleManager.startNotification(peripheral.id, service, characteristic).then(() => {
                            console.log('Started notification on ' + peripheral.id);
                            this.setState({connectedPeripheralId:peripheral.id});
                            Toast.info("连接成功",1);
                        }).catch((error) => {
                            console.log('Notification error', error);
                        });
                    });

                }).catch((error) => {
                    console.log('Connection error', error);
                });
            }
        }
    }

    servo = (position,angle)=>{
        const connectedPeripheralId = this.state.connectedPeripheralId;
        if(!connectedPeripheralId){
            BaiduASRModule.speak("没有可用的篮球架")
            return;
        }

        var msg = "";
        if(position == "down" && angle == "big"){
            msg = "down:big"
        }else if(position == "down" && angle == "small"){
            msg = "down:small"
        }else if(position == "up" && angle == "big"){
            msg = "up:big"
        }else if(position == "up" && angle == "small"){
            msg = "up:small"
        }else if(position == "down" && angle == "info"){
            msg = "down:info"
        }else if(position == "up" && angle == "info"){
            msg = "up:info"
        }

        var bytearray = [];

        for(var i=0;i<msg.length;i++){
            var code = msg.charCodeAt(i);
            bytearray.push(code);
        }
        BleManager.write(connectedPeripheralId, service, characteristic, bytearray).then(() => {});
    }

    sendMessageToDevice = ()=>{
        const connectedPeripheralId = this.state.connectedPeripheralId;
        if(!connectedPeripheralId){
            BaiduASRModule.speak("没有可用的篮球架")
            return;
        }
        var info = "time:start";
        BleManager.write(connectedPeripheralId, service, characteristic, this.stringToBytecustom(info)).then(() => {});
    }


    render(){
        var {height, width} = Dimensions.get('window');
        return (
            <View style={{flex:1}}>
                <Flex>
                    <Flex.Item>
                        <AgorachatNativeView uid={0} status={this.state.status} channel={this.state.channel} style={{height:height/2}}/>
                    </Flex.Item>
                    <Flex.Item>
                        {
                            this.state.players.map((item) => {
                                return <View key={item}>
                                    <AgorachatNativeView uid={item} status={0} channel={this.state.channel}
                                                         style={{height:height/2}}/>
                                </View>
                            })
                        }
                    </Flex.Item>
                </Flex>

                <View style={{position:'absolute',bottom:0,right:0}}>
                    <Text>{this.state.connectedPeripheralId?"智能篮球架连接成功":"智能篮球架未连接"}</Text>
                    <Text>
                        {this.state.isEnterMatch?"赛场进入成功":"没有进入赛场"}
                    </Text>
                    <Text>{this.state.currentTime}</Text>
                    <Text>{"本方得分："+this.state.myscore}</Text>
                    <Text>{"对方得分："+this.state.otherscore}</Text>
                    <Button onClick={()=>{
                        this.startScan();
                    }} size="large">连接智能篮球架</Button>
                    <Button onClick={()=>{this.setState({status:2})}}>离开房间</Button>
                </View>
            </View>);
    }
}