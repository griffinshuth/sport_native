import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    TextInput,
    StyleSheet,
    NativeModules,
    NativeEventEmitter,
    requireNativeComponent,
    Platform
} from 'react-native'
import {
    Button,
    Toast,
    WhiteSpace
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import LocalClientModule from "../NativeModules/LocalClientModule"

const LocalClientModuleEmitter = new NativeEventEmitter(LocalClientModule);

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            ip:"",
            isConnect:false,
            connectStatus:"没有连接服务器",
        }
    }
    componentDidMount(){
        LocalClientModule.startClient(8888,6666);
        this.onSearchServerTimeout_handler = LocalClientModuleEmitter.addListener("onSearchServerTimeout",this.onSearchServerTimeout);
        this.LocalClientSocketConnected_handler = LocalClientModuleEmitter.addListener("clientSocketConnected",this.LocalClientSocketConnected);
        this.LocalClientSocketDataa_handler = LocalClientModuleEmitter.addListener("clientReceiveData",this.LocalClientSocketData);
        this.LocalClientSocketClosed_handler = LocalClientModuleEmitter.addListener("clientSocketDisconnect",this.LocalClientSocketClosed);
    }
    componentWillUnmount(){
        LocalClientModule.stopClient();
        this.onSearchServerTimeout_handler.remove();
        this.LocalClientSocketConnected_handler.remove();
        this.LocalClientSocketDataa_handler.remove();
        this.LocalClientSocketClosed_handler.remove();
    }

    onSearchServerTimeout = ()=>{
        Toast.info("搜索失败")
    }

    LocalClientSocketConnected = ()=>{
        this.setState({
            isConnect:true,
            connectStatus:"服务器连接成功"
        })
        LocalClientModule.commonLogin(this.props.appNS.clientID);
    }

    LocalClientSocketData = (result)=>{
        Toast.info(result.data);
    }

    LocalClientSocketClosed = ()=>{
        this.setState({
            isConnect:false,
            connectStatus:"服务器连接断开"
        })
    }

    connect = ()=>{
        if(!this.state.isConnect && this.state.ip != ""){
            LocalClientModule.connectServer(this.state.ip);
        }
    }

    searchServer = ()=>{
        LocalClientModule.searchServer();
    }

    send = ()=>{
        if(this.state.isConnect){
            var json = {id:"test",extra:"sport"}
            var str = JSON.stringify(json);
            LocalClientModule.clientSend(str);
        }
    }

    render(){
        return (
            <View>
                <ToolBar title="热点客户端" navigation={this.props.navigation}/>
                <View>
                    <TextInput
                        style={{height: 40}}
                        placeholder="输入服务器IP地址"
                        onChangeText={(ip) => this.setState({ip})}
                        value={this.state.ip}
                    />
                    <View><Text>{this.state.connectStatus}</Text></View>
                    <Button onClick={this.connect}>连接指定IP的服务器</Button>
                    <Button onClick={this.searchServer}>搜索导播服务器</Button>
                    <WhiteSpace/>
                    <Button onClick={this.send}>发送</Button>
                </View>
            </View>
        )
    }
}