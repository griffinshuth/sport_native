import React from 'react'
import {
    View,
    Text,
    ScrollView,
    StyleSheet,
    NativeModules,
    DeviceEventEmitter
} from 'react-native'
import {
    Button,
    Toast,
    Flex,
    WhiteSpace
} from 'antd-mobile'
import {connect} from 'dva'
import ToolBar from '../../Components/ToolBar'
import Test from "antd-mobile/es/action-sheet/demo/basic.native";
var ClassicBlueToothModule = NativeModules.ClassicBlueToothModule;
var WiFiDirectModule = NativeModules.WiFiDirectModule;

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f5fcff'
    }
})

@connect()
export default class BTDiscover extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            isDiscovering:false,
            deviceList:[],
            wifiDirectDevices:[],
            isConnected:false, //点对点连接是否建立
            isSocketConnected:false, //socket连接是否建立
            groupRole:"闲散设备",
            maxkey:0
        }
    }

    componentWillMount(){
        //bluetooth
        DeviceEventEmitter.addListener('onBluetoothFounded',this.onBluetoothFounded);
        DeviceEventEmitter.addListener('onBluetoothDiscoverStarted',this.onBluetoothDiscoverStarted);
        DeviceEventEmitter.addListener('onBluetoothDiscoverEnded',this.onBluetoothDiscoverEnded);
        DeviceEventEmitter.addListener('onConnectAccepted',this.onConnectAccepted);
        DeviceEventEmitter.addListener('onDataReceived',this.onDataReceived);
        //WifiDirect
        //节点相关事件
        DeviceEventEmitter.addListener('onWifiDirectPeers',this.onWifiDirectPeers);
        DeviceEventEmitter.addListener('onWifiDirectPeerConnected',this.onWifiDirectPeerConnected);
        DeviceEventEmitter.addListener('onWifiDirectPeerDisconnected',this.onWifiDirectPeerDisconnected);
        DeviceEventEmitter.addListener('onWifiDirectPeerConnectFailed',this.onWifiDirectPeerConnectFailed);
        //数据客户端相关事件
        DeviceEventEmitter.addListener('onWifiDirectClientConnectError',this.onWifiDirectClientConnectError);
        DeviceEventEmitter.addListener('onWifiDirectClientConnected',this.onWifiDirectClientConnected);
        DeviceEventEmitter.addListener('onWifiDirectClientDisconnected',this.onWifiDirectClientDisconnected);
        DeviceEventEmitter.addListener('onWifiDirectClientDataReceived',this.onWifiDirectClientDataReceived);
        //数据服务器相关事件
        DeviceEventEmitter.addListener('onWifiDirectRemoteSocketConnected',this.onWifiDirectRemoteSocketConnected);
        DeviceEventEmitter.addListener("onWifiDirectRemoteSocketDisconnected",this.onWifiDirectRemoteSocketDisconnected);
        DeviceEventEmitter.addListener('onWifiDirectServerDataReceived',this.onWifiDirectServerDataReceived);
        DeviceEventEmitter.addListener('onWifiDirectServerRuning',this.onWifiDirectServerRuning);
    }

    componentWillUnmount(){
        //bluetooth
        DeviceEventEmitter.removeListener('onBluetoothFounded',this.onBluetoothFounded);
        DeviceEventEmitter.removeListener('onBluetoothDiscoverStarted',this.onBluetoothDiscoverStarted);
        DeviceEventEmitter.removeListener('onBluetoothDiscoverEnded',this.onBluetoothDiscoverEnded);
        DeviceEventEmitter.removeListener('onConnectAccepted',this.onConnectAccepted);
        DeviceEventEmitter.removeListener('onDataReceived',this.onDataReceived);
        //wifidirect
        DeviceEventEmitter.removeListener('onWifiDirectPeers',this.onWifiDirectPeers);
        DeviceEventEmitter.removeListener('onWifiDirectPeerConnected',this.onWifiDirectPeerConnected);
        DeviceEventEmitter.removeListener('onWifiDirectPeerDisconnected',this.onWifiDirectPeerDisconnected);
        DeviceEventEmitter.removeListener("onWifiDirectPeerConnectFailed",this.onWifiDirectPeerConnectFailed);

        DeviceEventEmitter.removeListener('onWifiDirectClientConnectError',this.onWifiDirectClientConnectError);
        DeviceEventEmitter.removeListener('onWifiDirectClientConnected',this.onWifiDirectClientConnected);
        DeviceEventEmitter.removeListener('onWifiDirectClientDisconnected',this.onWifiDirectClientDisconnected);
        DeviceEventEmitter.removeListener('onWifiDirectClientDataReceived',this.onWifiDirectClientDataReceived);

        DeviceEventEmitter.removeListener('onWifiDirectRemoteSocketConnected',this.onWifiDirectRemoteSocketConnected);
        DeviceEventEmitter.removeListener('onWifiDirectRemoteSocketDisconnected',this.onWifiDirectRemoteSocketDisconnected);
        DeviceEventEmitter.removeListener('onWifiDirectServerDataReceived',this.onWifiDirectServerDataReceived);
        DeviceEventEmitter.removeListener('onWifiDirectServerRuning',this.onWifiDirectServerRuning);
    }

    onBluetoothFounded = (e)=>{
        var temp = this.state.deviceList;
        temp.push({
            "DeviceName":e.DeviceName,
            "Address":e.Address,
            "bonded":e.bonded,
            "connected":e.connected,
            "key":this.state.maxkey
        });
        this.setState({deviceList:temp});
        this.setState({maxkey:this.state.maxkey+1})
    }
    onBluetoothDiscoverStarted=(e)=>{
        this.setState({isDiscovering:true})
        this.setState({deviceList:[]});
    }
    onBluetoothDiscoverEnded=(e)=>{
        this.setState({isDiscovering:false})
    }
    onConnectAccepted=(e)=>{
        Toast.info("远端连接被接受："+e.name);
    }
    onDataReceived=(e)=>{
        Toast.info(e.data);
    }

    //wifidirect callback begin
    onWifiDirectPeers=(result)=>{
        var devices = []
        for(var i=0;i<result.peerlist.length;i++){
            var d = {};
            d.Address = result.peerlist[i].Address;
            d.name = result.peerlist[i].name;
            d.isConnected = false;
            devices.push(d);
        }
        this.setState({wifiDirectDevices:devices});
    }
    onWifiDirectPeerConnected=(e)=>{
        if(e.type == 'GroupOwner'){
            //对于拥有者来说，成员连接和断开都会触发这个事件，除非最后一个连接的成员断开连接，既触发事件的时候，仍然有成员连接，则拥有者就处于连接状态
            Toast.info("以所有者身份建立Wi-Fi连接或成员断开Wi-Fi连接")
            this.setState({isConnected:true,groupRole:"群组拥有者"});
        }else{
            Toast.info("以成员身份建立Wi-Fi连接")
            this.setState({isConnected:true,groupRole:"群组成员"});
        }
    }
    onWifiDirectPeerDisconnected = (e)=>{
        Toast.info("Wifi连接断开")
        this.setState({isConnected:false,groupRole:"闲散设备"});

    }
    onWifiDirectPeerConnectFailed = ()=>{
        Toast.info("Wi-Fi连接失败")
    }

    onWifiDirectClientConnectError = ()=>{
        Toast.info("socket连接失败")
    }
    onWifiDirectClientConnected = ()=>{
        Toast.info("socket连接成功");
        this.setState({isSocketConnected:true})
    }
    onWifiDirectClientDisconnected = ()=>{
        Toast.info("socket连接断开");
        this.setState({isSocketConnected:false})
    }
    onWifiDirectClientDataReceived = (result)=>{
        Toast.info(result.data);
    }

    onWifiDirectRemoteSocketConnected = ()=>{
        Toast.info("接受远端连接")
    }
    onWifiDirectRemoteSocketDisconnected =()=>{
        Toast.info("远端连接断开")
    }
    onWifiDirectServerDataReceived = (result)=>{
        Toast.info(result.data);
    }
    onWifiDirectServerRuning = ()=>{
        Toast.info("socket服务器启动成功")
    }
    //wifidirect callback end

    async chooseFile(){
        var result = await ClassicBlueToothModule.chooseFile();
        Toast.info(result);
    }

    searchNearby(){
        ClassicBlueToothModule.searchNearby();
    }

    async connect(item){
        //Toast.info(address);
        if(item.connected){
            var result = await ClassicBlueToothModule.BTDisconnect(item.Address);
            Toast.info(result);
            if(result == "success"){
                ClassicBlueToothModule.searchNearby();
            }
        }else{
            var result = await ClassicBlueToothModule.BTConnect(item.Address);
            Toast.info(result);
        }
    }

    async openDiscoverable(){
        var code = await ClassicBlueToothModule.openDiscoverable();
        Toast.info(code);
    }

    async sendData(item){
        var result = await ClassicBlueToothModule.sendBTData(item.Address,"hello world");
        Toast.info(result);
    }

    discoverPeers(){
        WiFiDirectModule.discoverPeers();
    }

    render(){
        var self = this;
        return (
            <View style={styles.container}>
                <ToolBar title="蓝牙搜索" navigation={this.props.navigation}/>
                <ScrollView showsVerticalScrollIndicator={false} style={{flex:1}}>
                    <Button onClick={()=>this.searchNearby()} loading={this.state.isDiscovering}>蓝牙搜索</Button>
                    <Button>停止搜索</Button>
                    <Button onClick={()=>{this.chooseFile()}}>选择文件</Button>
                    <Button onClick={()=>this.openDiscoverable()}>打开蓝牙可发现性</Button>
                    <WhiteSpace/>
                    <Button onClick={()=>this.discoverPeers()}>Wi-Fi Direct扫描</Button>
                    <View>
                        {
                            this.state.deviceList.map((item,index) => {
                                return(
                                    <View key={item.key}>
                                        <Flex>
                                        <Text style={{flex:2}}>
                                            <Text>{item.DeviceName}:</Text>
                                            <Text>{item.connected?"连接中":item.bonded?"配对":"未配对"}</Text>
                                        </Text>
                                        <Button onClick={()=>self.connect(item)} style={{flex:1}} type="primary" inline>
                                            {item.connected?"断开连接":"连接"}</Button>
                                            <Button onClick={()=>self.sendData(item)} style={{flex:1}} type="primary" inline>
                                                发送</Button>
                                        </Flex>
                                    </View>
                                    )

                            })
                        }
                    </View>
                    <View>
                        <View><Text>{this.state.isConnected?"连接成功":"未连接"}</Text></View>
                        <View><Text>{this.state.groupRole}</Text></View>
                        <Button onClick={()=>{
                            if(this.state.isConnected)
                                WiFiDirectModule.wifiDirectDisconnect();
                        }}>断开连接</Button>
                        {
                            this.state.wifiDirectDevices.map((item,index) => {
                               return (<View key={item.Address}>
                                   <View><Text>Address:{item.Address}</Text></View>
                                   <View><Text>Name:{item.name}</Text></View>
                                   <Button onClick={()=>{
                                       if(!this.state.isConnected)
                                           WiFiDirectModule.wifiDirectConnect(item.Address);
                                       else
                                           Toast.info("一台设备只能在一个group中")
                                   }}>建立Wi-Fi连接</Button>
                                   </View>)
                            })
                        }
                        <WhiteSpace/>
                        <Button onClick={()=>{
                            if(this.state.isConnected && this.state.groupRole == "群组成员" && !this.state.isSocketConnected){
                                WiFiDirectModule.connectServer();
                            }
                        }}>连接服务器</Button>
                        <Button onClick={()=>{
                            if(this.state.isConnected && this.state.groupRole == "群组成员" && this.state.isSocketConnected){
                                WiFiDirectModule.clientSendData("hello")
                            }
                        }}>发送数据</Button>
                    </View>
                </ScrollView>
            </View>
        )
    }
}