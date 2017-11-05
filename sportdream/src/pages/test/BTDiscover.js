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
    Flex
} from 'antd-mobile'
import {connect} from 'dva'
import ToolBar from '../../Components/ToolBar'
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
            wifiDirectDevice:null,
            maxkey:0
        }
    }

    componentWillMount(){
        DeviceEventEmitter.addListener('onBluetoothFounded',this.onBluetoothFounded);
        DeviceEventEmitter.addListener('onBluetoothDiscoverStarted',this.onBluetoothDiscoverStarted);
        DeviceEventEmitter.addListener('onBluetoothDiscoverEnded',this.onBluetoothDiscoverEnded);
        DeviceEventEmitter.addListener('onConnectAccepted',this.onConnectAccepted);
        DeviceEventEmitter.addListener('onDataReceived',this.onDataReceived);
        DeviceEventEmitter.addListener('onWifiDirectPeers',this.onWifiDirectPeers);
        DeviceEventEmitter.addListener('onWifiDirectConnected',this.onWifiDirectConnected);
    }

    componentWillUnmount(){
        DeviceEventEmitter.removeListener('onBluetoothFounded',this.onBluetoothFounded);
        DeviceEventEmitter.removeListener('onBluetoothDiscoverStarted',this.onBluetoothDiscoverStarted);
        DeviceEventEmitter.removeListener('onBluetoothDiscoverEnded',this.onBluetoothDiscoverEnded);
        DeviceEventEmitter.removeListener('onConnectAccepted',this.onConnectAccepted);
        DeviceEventEmitter.removeListener('onDataReceived',this.onDataReceived);
        DeviceEventEmitter.removeListener('onWifiDirectPeers',this.onWifiDirectPeers);
        DeviceEventEmitter.removeListener('onWifiDirectConnected',this.onWifiDirectConnected);
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
    onWifiDirectPeers=(e)=>{
        Toast.info(JSON.stringify(e));
        this.setState({wifiDirectDevice:e});
    }
    onWifiDirectConnected=(e)=>{
        Toast.info(JSON.stringify(e));
    }
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
    wifiDirectConnect=()=>{
        if(this.state.wifiDirectDevice){
            WiFiDirectModule.wifiDirectConnect(this.state.wifiDirectDevice.Address);
        }else{
            Toast.info("没有可以连接的设备")
        }

    }

    wifiDirectSendData(){
        WiFiDirectModule.wifiDirectSendData("sport")
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
                    <Button onClick={()=>this.openDiscoverable()}>打开可发现性</Button>
                    <Button onClick={()=>this.discoverPeers()}>Wi-Fi Direct扫描</Button>
                    <Button onClick={()=>this.wifiDirectConnect()}>Wi-Fi Direct连接</Button>
                    <Button onClick={()=>this.wifiDirectSendData()}>发送数据</Button>
                    <View>
                        {
                            this.state.deviceList.map(function (item,index) {
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
                </ScrollView>
            </View>
        )
    }
}