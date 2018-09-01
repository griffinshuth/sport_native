import React from 'react'
import {
    StyleSheet,
    View,
    Text,
    requireNativeComponent,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    Platform,
    Dimensions
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast,
    Flex
} from 'antd-mobile'
import Orientation from 'react-native-orientation';

import ToolBar from '../../Components/ToolBar'
import AgorachatNativeView from '../../NativeViews/AgorachatView'
var AgorachatModule = NativeModules.AgorachatViewManager;

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            myuid:null,
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
        this.setState({players:[...this.state.players,0]})
        Orientation.lockToLandscape();
        AgorachatModule.joinChannel("test")
        this.joinChannelSuccess_subscription = NativeAppEventEmitter.addListener(
            'joinChannelSuccess',
            (data)=>{
                //Toast.info(data.myuid);
                this.setState({myuid:data.myuid});
            }
        )
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
        var {height, width} = Dimensions.get('window');
        return (
        <View style={{flex:1}}>
            <Flex>
            {
                this.state.players.map((item)=>{
                    return <Flex.Item key={item}>
                        <AgorachatNativeView uid={item} style={{height:height}}/>
                    </Flex.Item>
                })
            }
            </Flex>
            <View style={{position:'absolute',bottom:0,right:0}}>
                <Button onClick={()=>{this.props.navigation.goBack()}} size="large">返回</Button>
                <WhiteSpace/>
                <Button onClick={this.record} size="large">{this.state.isPushing?"stop":"start"}</Button>
            </View>
        </View>);
    }
}