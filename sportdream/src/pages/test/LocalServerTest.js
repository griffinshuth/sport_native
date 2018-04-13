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
var LocalNetModule = NativeModules.LocalNetModule;
const LocalNetModuleEmitter = new NativeEventEmitter(LocalNetModule);

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            remoteClient:[]
        }
    }
    componentDidMount(){
        this.serverReceiveData_handler = LocalNetModuleEmitter.addListener("serverReceiveData",this.serverReceiveData);
        this.serverSocketDisconnect_handler = LocalNetModuleEmitter.addListener("serverSocketDisconnect",this.serverSocketDisconnect);
        LocalNetModule.startServer(4567,5678);
    }
    componentWillUnmount(){
        this.serverReceiveData_handler.remove();
        this.serverSocketDisconnect_handler.remove();
        LocalNetModule.stopServer();
    }
    serverReceiveData = (result)=>{
        //Toast.info(JSON.stringify(result));
        var client = {deviceID:result.deviceID,name:result.name}
        this.setState({remoteClient:[...this.state.remoteClient,client]});
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
        LocalNetModule.serverSend(str,deviceID);
    }

    render(){
        return (
            <View>
                <ToolBar title="热点服务器" navigation={this.props.navigation}/>
                <View>
                    {this.state.remoteClient.length==0?<Text>没有客户端</Text>:this.state.remoteClient.map((item,index) => {
                        return (<View key={item.deviceID}>
                            <Text>{item.name}</Text>
                            <Button onClick={()=>{this.talkToClient(index)}}>发送</Button>
                        </View>)
                    })}
                </View>
            </View>
        )
    }
}