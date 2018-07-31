import React, { Component } from 'react';
import {
    View,
    Text,
    StyleSheet,
    NativeModules,
    requireNativeComponent,
    NativeEventEmitter
} from 'react-native'
import {
    Toast,
    WhiteSpace,
    Button,
    Flex
} from 'antd-mobile'
const BLEPeripheralModule = NativeModules.BLEPeripheralModule;
const BLEPeripheralEmmiter = new NativeEventEmitter(BLEPeripheralModule);
import ToolBar from '../../Components/ToolBar'

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#FFF',
    },

});

export default class App extends Component{
    constructor(props){
        super(props);
        this.state = {
            centrals:[]
        }
    }

    componentWillMount(){

    }

    componentDidMount(){
        this.peripheralManagerDidStartAdvertising_handler = BLEPeripheralEmmiter.addListener("peripheralManagerDidStartAdvertising",this.peripheralManagerDidStartAdvertising);
        this.sendToAllSubscribersError_handler = BLEPeripheralEmmiter.addListener("sendToAllSubscribersError",this.sendToAllSubscribersError);
        this.reSendToAllSubscribersError_handler = BLEPeripheralEmmiter.addListener("reSendToAllSubscribersError",this.reSendToAllSubscribersError);
        this.sendToSingleSubscriberError_handler = BLEPeripheralEmmiter.addListener("sendToSingleSubscriberError",this.sendToSingleSubscriberError);
        this.didSubscribeToCharacteristic_handler = BLEPeripheralEmmiter.addListener("didSubscribeToCharacteristic",this.didSubscribeToCharacteristic);
        this.didUnsubscribeFromCharacteristic_handler = BLEPeripheralEmmiter.addListener("didUnsubscribeFromCharacteristic",this.didUnsubscribeFromCharacteristic);
        this.didReceiveWriteRequests_handler = BLEPeripheralEmmiter.addListener("didReceiveWriteRequests",this.didReceiveWriteRequests);
        BLEPeripheralModule.startPeripheral();
    }

    componentWillUnmount(){
        this.peripheralManagerDidStartAdvertising_handler.remove();
        this.sendToAllSubscribersError_handler.remove();
        this.reSendToAllSubscribersError_handler.remove();
        this.sendToSingleSubscriberError_handler.remove();
        this.didSubscribeToCharacteristic_handler.remove();
        this.didUnsubscribeFromCharacteristic_handler.remove();
        this.didReceiveWriteRequests_handler.remove();
        BLEPeripheralModule.stopPeripheral();

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

    render(){
        return (
            <View style={styles.container}>
                <ToolBar title="BLE外围设备" navigation={this.props.navigation}/>
                <Button onClick={()=>{BLEPeripheralModule.notifyAllDevice("大家好")}}>群发</Button>
                {this.state.centrals.map((item,index)=>{
                    return (
                        <View key={item.uuid}>
                            <Text>{item.uuid}</Text>
                            <Flex>
                                <Flex.Item><Button onClick={()=>{BLEPeripheralModule.notifyDeviceByUUID("hello",item.uuid)}}>发送消息</Button></Flex.Item>
                            </Flex>
                        </View>
                    )
                })}
            </View>
        )
    }
}