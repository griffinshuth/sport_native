import React from 'react'
import {connect} from 'dva'
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
var LocalNetModule = NativeModules.LocalNetModule;
const LocalNetModuleEmitter = new NativeEventEmitter(LocalNetModule);

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    componentDidMount(){
        this.serverDiscovered_handler = LocalNetModuleEmitter.addListener("serverDiscovered",this.serverDiscovered);
        this.clientReceiveData_handler = LocalNetModuleEmitter.addListener("clientReceiveData",this.clientReceiveData);
        LocalNetModule.startClient(4567,5678);
    }
    componentWillUnmount(){
        this.serverDiscovered_handler.remove();
        this.clientReceiveData_handler.remove();
        LocalNetModule.stopClient();
    }
    search = ()=>{
        LocalNetModule.searchServer();
    }
    send = ()=>{
        var clientID = this.props.appNS.clientID;
        var json = {id:"login",deviceID:clientID,name:"技术统计"}
        var str = JSON.stringify(json);
        LocalNetModule.clientSend(str);
    }
    serverDiscovered = ()=>{
        Toast.info("server discovered")
    }
    clientReceiveData = (result)=>{
        Toast.info(result.data);
    }
    render(){
        return (
            <View>
                <ToolBar title="热点客户端" navigation={this.props.navigation}/>
                <View>
                    <Button onClick={this.search}>搜索和连接热点服务器</Button>
                    <WhiteSpace/>
                    <Button onClick={this.send}>发送</Button>
                </View>
            </View>
        )
    }
}