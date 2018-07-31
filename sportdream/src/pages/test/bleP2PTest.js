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
    WhiteSpace,
    Button,
    Flex
} from 'antd-mobile'
import Dimensions from 'Dimensions';
import BleManager from 'react-native-ble-manager';
import TimerMixin from 'react-timer-mixin';
import reactMixin from 'react-mixin';
import ToolBar from '../../Components/ToolBar'
import RemoteControlNativeView from '../../NativeViews/RemoteControlView'
const BLEPeripheralModule = NativeModules.BLEPeripheralModule;
const BLEPeripheralEmmiter = new NativeEventEmitter(BLEPeripheralModule);

var Sound = require('react-native-sound')

const window = Dimensions.get('window');
const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});

const BleManagerModule = NativeModules.BleManager;
const bleManagerEmitter = new NativeEventEmitter(BleManagerModule);

//智能篮球架uuid
/*var service = "FFE0";
var characteristic = "FFE1";*/

//P2P
var service = "00007e57-0000-1000-8000-00805f9b34fb";
var characteristic = "13333333-3333-3333-3333-333333330003";

export default class App extends Component {
    constructor(){
        super()

        this.state = {
            scanning:false,
            peripherals: new Map(),
            appState: '',
            centrals:[]
        }

        this.handleDiscoverPeripheral = this.handleDiscoverPeripheral.bind(this);
        this.handleStopScan = this.handleStopScan.bind(this);
        this.handleUpdateValueForCharacteristic = this.handleUpdateValueForCharacteristic.bind(this);
        this.handleDisconnectedPeripheral = this.handleDisconnectedPeripheral.bind(this);
        this.handleAppStateChange = this.handleAppStateChange.bind(this);
    }

    componentWillMount(){

    }

    componentDidMount() {
        this.peripheralManagerDidStartAdvertising_handler = BLEPeripheralEmmiter.addListener("peripheralManagerDidStartAdvertising",this.peripheralManagerDidStartAdvertising);
        this.sendToAllSubscribersError_handler = BLEPeripheralEmmiter.addListener("sendToAllSubscribersError",this.sendToAllSubscribersError);
        this.reSendToAllSubscribersError_handler = BLEPeripheralEmmiter.addListener("reSendToAllSubscribersError",this.reSendToAllSubscribersError);
        this.sendToSingleSubscriberError_handler = BLEPeripheralEmmiter.addListener("sendToSingleSubscriberError",this.sendToSingleSubscriberError);
        this.didSubscribeToCharacteristic_handler = BLEPeripheralEmmiter.addListener("didSubscribeToCharacteristic",this.didSubscribeToCharacteristic);
        this.didUnsubscribeFromCharacteristic_handler = BLEPeripheralEmmiter.addListener("didUnsubscribeFromCharacteristic",this.didUnsubscribeFromCharacteristic);
        this.didReceiveWriteRequests_handler = BLEPeripheralEmmiter.addListener("didReceiveWriteRequests",this.didReceiveWriteRequests);
        BLEPeripheralModule.startPeripheral();

        AppState.addEventListener('change', this.handleAppStateChange);

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

        //播放声音
        //Sound.setCategory("PlayAndRecord");
        Sound.setCategory("Playback");
        this.whoosh = new Sound('silence10sec.mp3', Sound.MAIN_BUNDLE, (error) => {
            if (error) {
                console.log('failed to load the sound', error);
                return;
            }
            // loaded successfully
            console.log('duration in seconds: ' + this.whoosh.getDuration() + 'number of channels: ' + this.whoosh.getNumberOfChannels());

            // Play the sound with an onEnd callback
            this.whoosh.play((success) => {
                if (success) {
                    console.log('successfully finished playing');
                } else {
                    console.log('playback failed due to audio decoding errors');
                    // reset the player to its uninitialized state (android only)
                    // this is the only option to recover after an error occured and use the player again
                    this.whoosh.reset();
                }
            });

            // Reduce the volume by half
            this.whoosh.setVolume(0.5);

            // Position the sound to the full right in a stereo field
            this.whoosh.setPan(1);

            // Loop indefinitely until stop() is called
            this.whoosh.setNumberOfLoops(-1);
        });
    }

    handleAppStateChange(nextAppState) {
        if (this.state.appState.match(/inactive|background/) && nextAppState === 'active') {
            console.log('App has come to the foreground!')
            BleManager.getConnectedPeripherals([]).then((peripheralsArray) => {
                console.log('Connected peripherals: ' + peripheralsArray.length);
            });
        }
        //this.setState({appState: nextAppState});
    }

    componentWillUnmount() {
        this.peripheralManagerDidStartAdvertising_handler.remove();
        this.sendToAllSubscribersError_handler.remove();
        this.reSendToAllSubscribersError_handler.remove();
        this.sendToSingleSubscriberError_handler.remove();
        this.didSubscribeToCharacteristic_handler.remove();
        this.didUnsubscribeFromCharacteristic_handler.remove();
        this.didReceiveWriteRequests_handler.remove();
        BLEPeripheralModule.stopPeripheral();

        this.handlerDiscover.remove();
        this.handlerStop.remove();
        this.handlerDisconnect.remove();
        this.handlerUpdate.remove();
        this.whoosh.stop(() => {

        });
        // Release the audio player resource
        this.whoosh.release();
        const list = Array.from(this.state.peripherals.values());
        for(var i=0;i<list.length;i++){
            BleManager.disconnect(list[i].id);
        }
    }

    handleDisconnectedPeripheral(data) {
        let peripherals = this.state.peripherals;
        let peripheral = peripherals.get(data.peripheral);
        if (peripheral) {
            peripheral.connected = false;
            peripherals.set(peripheral.id, peripheral);
            this.setState({peripherals});
        }
        console.log('Disconnected from ' + data.peripheral);
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

    handleUpdateValueForCharacteristic(data) {
        //智能篮球架协议解析
        /*console.log('Received data from ' + data.peripheral + ' characteristic ' + data.characteristic, data.value);
        var msg = "";
        for(var i=0;i<data.value.length;i++){
            var t = String.fromCharCode(data.value[i]);
            msg += t;
        }
        Toast.info(msg,1);*/

        //P2P
        Toast.info(this.bytesToStringcustom(data.value));
    }

    handleStopScan() {
        console.log('Scan is stopped');
        this.setState({ scanning: false });
    }

    reset = ()=>{
        const list = Array.from(this.state.peripherals.values());
        for(var i=0;i<list.length;i++){
            BleManager.disconnect(list[i].id);
        }
        this.setState({peripherals:new Map()})
    }

    startScan() {
        if (!this.state.scanning) {
            this.reset();
            BleManager.scan([], 3, true).then((results) => {
                console.log('Scanning...');
                this.setState({scanning:true});
            });
        }
    }

    handleDiscoverPeripheral(peripheral){
        var peripherals = this.state.peripherals;
        if (!peripherals.has(peripheral.id)){
            console.log('Got ble peripheral', peripheral);
            peripherals.set(peripheral.id, peripheral);
            this.setState({ peripherals })
        }
    }

    remoteControlCommand = (event)=>{
        //Toast.info(JSON.stringify(event.nativeEvent));
        //return;
        if(!this.activePeripheralid){
            console.log(this.activePeripheralid)
            Toast.info("没有可用设备",1)
            return;
        }
        var bytearray = [];
        if(event.nativeEvent.type == "small"){
            var msg = "small";
        }else if(event.nativeEvent.type == "big"){
            var msg = "big"
        }else if(event.nativeEvent.type == "Play"){
            var msg = "play"
        }
        else{
            Toast.info("远程事件类型无法识别")
            return;
        }

        for(var i=0;i<msg.length;i++){
            var code = msg.charCodeAt(i);
            bytearray.push(code);
        }
        console.log(this.activePeripheralid);
        BleManager.write(this.activePeripheralid, service, characteristic, bytearray).then(() => {});
    }

    connectDevice = (peripheral) => {
        if(peripheral){
            if (peripheral.connected){
                BleManager.disconnect(peripheral.id);
            }else{
                BleManager.connect(peripheral.id).then(()=>{
                    let peripherals = this.state.peripherals;
                    let p = peripherals.get(peripheral.id);
                    if (p) {
                        p.connected = true;
                        peripherals.set(peripheral.id, p);
                        this.setState({peripherals});
                    }
                    console.log('Connected to ' + peripheral.id);

                    BleManager.retrieveServices(peripheral.id).then((peripheralInfo) => {
                        console.log(peripheralInfo);
                        BleManager.startNotification(peripheral.id, service, characteristic).then(() => {
                            console.log('Started notification on ' + peripheral.id);
                            Toast.info("连接成功",1)
                            this.activePeripheralid = peripheral.id;
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

    peripheralManagerDidStartAdvertising = ()=>{
        Toast.info("startPeripheral");
    }

    sendToAllSubscribersError = ()=>{
        Toast.info("发送群发消息失败")
    }

    reSendToAllSubscribersError = ()=>{
        Toast.info("重新发送群发消息失败")
    }

    sendToSingleSubscriberError = ()=>{
        Toast.info("发送单个订阅消息失败")
    }

    didSubscribeToCharacteristic = (result)=>{
        var uuid = result.CentralUUID;
        this.setState({centrals:[...this.state.centrals,{uuid:uuid}]});
    }

    didUnsubscribeFromCharacteristic = (result)=>{
        var uuid = result.CentralUUID;
        this.setState({centrals:this.state.centrals.filter((item,index)=>{
            if(item.uuid == uuid){
                return false;
            }else{
                return true;
            }
        })})
    }

    didReceiveWriteRequests = (result)=>{
        var uuid = result.CentralUUID;
        var value = result.value;
        Toast.info(value);
    }

    render() {
        const list = Array.from(this.state.peripherals.values());
        const dataSource = ds.cloneWithRows(list);


        return (
            <View style={styles.container}>
                <ToolBar title="BLE P2P" navigation={this.props.navigation}/>
                {Platform.OS == 'ios'?<RemoteControlNativeView onChange={this.remoteControlCommand}/>:null}
                <TouchableHighlight style={{marginTop: 40,margin: 20, padding:20, backgroundColor:'#ccc'}} onPress={() => this.startScan() }>
                    <Text>Scan Bluetooth ({this.state.scanning ? 'on' : 'off'})</Text>
                </TouchableHighlight>
                <ScrollView style={styles.scroll}>
                    <Button onClick={()=>{BLEPeripheralModule.notifyAllDevice("大家好")}}>群发</Button>
                    {this.state.centrals.map((item,index)=>{
                        return (
                            <View>
                                <Text>{item.uuid}</Text>
                                <Flex>
                                    <Flex.Item><Button onClick={()=>{BLEPeripheralModule.notifyDeviceByUUID("hello",item.uuid)}}>发送消息</Button></Flex.Item>
                                </Flex>
                            </View>
                        )
                    })}
                    {(list.length == 0) &&
                    <View style={{flex:1, margin: 20}}>
                        <Text style={{textAlign: 'center'}}>No peripherals</Text>
                    </View>
                    }
                    <ListView
                        enableEmptySections={true}
                        dataSource={dataSource}
                        renderRow={(item) => {
                            const color = item.connected ? 'green' : '#fff';
                            return (

                                <View style={[styles.row, {backgroundColor: color}]}>
                                    <TouchableHighlight onPress={() => this.connectDevice(item) }>
                                        <View>
                                            <Text style={{fontSize: 12, textAlign: 'center', color: '#333333', padding: 10}}>{item.name}</Text>
                                            <Text style={{fontSize: 8, textAlign: 'center', color: '#333333', padding: 10}}>{item.id}</Text>
                                        </View>
                                    </TouchableHighlight>
                                    <Button onClick={()=>{
                                        BleManager.readRSSI(item.id)
                                            .then((rssi) => {
                                                // Success code
                                                console.log('Current RSSI: ' + rssi);
                                                Toast.info(rssi,1);
                                            })
                                            .catch((error) => {
                                                // Failure code
                                                console.log(error);
                                            });
                                    }}>获得RSSI</Button>
                                    <Button onClick={()=>{
                                        var json = {user:"科比"};
                                        var info = JSON.stringify(json);
                                        BleManager.write(item.id, service, characteristic, this.stringToBytecustom(info)).then(() => {});
                                    }}>发送信息</Button>
                                    <Button onClick={()=>{
                                        BleManager.read(item.id, service, characteristic).then((data) => {
                                            Toast.info(this.bytesToStringcustom(data));
                                        });
                                    }}>读取消息</Button>
                                </View>

                            );
                        }}
                    />
                </ScrollView>
            </View>
        );
    }
}
reactMixin(App.prototype, TimerMixin);

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#FFF',
        width: window.width,
        height: window.height
    },
    scroll: {
        flex: 1,
        backgroundColor: '#f0f0f0',
        margin: 10,
    },
    row: {
        margin: 10
    },
});