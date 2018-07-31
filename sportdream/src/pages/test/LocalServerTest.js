import React from 'react'
import {
    View,
    Text,
    StyleSheet,
    NativeModules,
    NativeEventEmitter
} from 'react-native'
import {
    Button,
    Toast,
    WhiteSpace
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
var LocalServerModule = NativeModules.LocalServerModule;
const LocalServerModuleEmitter = new NativeEventEmitter(LocalServerModule);
import { NetworkInfo } from 'react-native-network-info';

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            remoteClient:[]
        }
    }
    componentDidMount(){
        this.serverReceiveData_handler = LocalServerModuleEmitter.addListener("serverReceiveData",this.serverReceiveData);
        this.serverSocketDisconnect_handler = LocalServerModuleEmitter.addListener("remoteSocketDisconnect",this.serverSocketDisconnect);
        this.onRemoteClientLogined_handler = LocalServerModuleEmitter.addListener("onRemoteClientLogined",this.onRemoteClientLogined);
        NetworkInfo.getIPAddress(ipv4 => {
            LocalServerModule.startServer(ipv4,8888,6666);
        });
    }
    componentWillUnmount(){
        this.serverReceiveData_handler.remove();
        this.serverSocketDisconnect_handler.remove();
        this.onRemoteClientLogined_handler.remove();
        LocalServerModule.stopServer();
    }
    onRemoteClientLogined = (result)=>{
        var client = {deviceID:result.deviceID}
        this.setState({remoteClient:[...this.state.remoteClient,client]});
    }
    serverReceiveData = (result)=>{
        Toast.info(result.json_str);
    }
    serverSocketDisconnect = (result)=>{
        var deviceID = result.deviceID;
        this.setState({remoteClient:this.state.remoteClient.filter(function (item,index) {
            return item.deviceID != deviceID;
        })})
    }

    talkToClient = (index)=>{
        var deviceID = this.state.remoteClient[index].deviceID;
        var json = {id:"test",extra:"ball"}
        var str = JSON.stringify(json);
        LocalServerModule.serverSend(str,deviceID);
    }

    render(){
        return (
            <View>
                <ToolBar title="热点服务器" navigation={this.props.navigation}/>
                <View>
                    {this.state.remoteClient.length==0?<Text>没有客户端</Text>:this.state.remoteClient.map((item,index) => {
                        return (<View key={item.deviceID}>
                            <Text>{item.deviceID}</Text>
                            <Button onClick={()=>{this.talkToClient(index)}}>发送</Button>
                        </View>)
                    })}
                </View>
            </View>
        )
    }
}