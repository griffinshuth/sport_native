import React from 'react'
import {
    StyleSheet,
    View,
    Text,
    requireNativeComponent,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    Platform
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast
} from 'antd-mobile'
import Orientation from 'react-native-orientation';

import ToolBar from '../../Components/ToolBar'
import AgorachatNativeView from '../../NativeViews/AgorachatView'
var AgorachatModule = NativeModules.AgorachatViewManager;

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            players : [],
            isPushing:false
        }

    }

    record = ()=>{
        if(!this.state.isPushing){
            AgorachatModule.startRCTRecord();
        }else{
            AgorachatModule.stopRCTRecord();
        }
        this.setState({isPushing:!this.state.isPushing});
    }

    componentWillMount(){
        AgorachatModule.initAgora();
    }

    componentDidMount(){
        if(Platform.OS != 'ios'){
            return;
        }
        Orientation.lockToLandscape();
        AgorachatModule.joinChannel("test")
        this.firstRemoteVideoDecoded_subscription = NativeAppEventEmitter.addListener(
            'firstRemoteVideoDecoded',
            (data) => {
                this.state.players.push(data.uid);
                this.setState({players:this.state.players})
            }
        );

        this.didOffline_subscription = NativeAppEventEmitter.addListener(
            'didOffline',
            (data) => {
                var index = this.state.players.indexOf(data.uid);
                if(index>=0){
                    this.state.players.splice(index,1);
                    this.setState({players:this.state.players})
                }
            }
        );
    }

    componentWillUnmount(){
        if(Platform.OS != 'ios'){
            return;
        }
        Orientation.lockToPortrait();
        AgorachatModule.leaveChannel();
        this.firstRemoteVideoDecoded_subscription.remove();
        this.didOffline_subscription.remove();

        AgorachatModule.destroyAgora();
    }

    render(){
        return (
        <View style={{flex:1}}>
            <AgorachatNativeView uid={0} style={{width:160,height:120}}/>
            {
                this.state.players.map((item)=>{
                    return <View key={item}>
                        <WhiteSpace/>
                        <AgorachatNativeView uid={item} style={{width:160,height:120}}/>
                    </View>
                })
            }
            <View style={{position:'absolute',bottom:0,right:0}}>
                <Button onClick={()=>{this.props.navigation.goBack()}} size="large">返回</Button>
                <WhiteSpace/>
                <Button onClick={this.record} size="large">{this.state.isPushing?"stop":"start"}</Button>
            </View>
        </View>);
    }
}