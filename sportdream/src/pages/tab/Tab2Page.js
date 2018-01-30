import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    Platform,
    requireNativeComponent,
    NativeModules,
    DeviceEventEmitter,
    NativeAppEventEmitter
} from 'react-native'
var EaseMessageView = requireNativeComponent('EaseMessageView', null);

import Dimensions from 'Dimensions';

import {
    WhiteSpace,
    Toast,
    Button
} from 'antd-mobile'

import {NavigationActions} from 'react-navigation'
import {connect} from 'dva'

@connect()
export default class Tab2Page extends Component{
    static navigationOptions = {
        tabBarLabel:'关系',
        tabBarIcon: ({ focused, tintColor }) =>
            <Image
                style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                source={require('../../assets/images/relation.png')}
            />,
    }

    constructor(props){
        super(props);
        this.state = {
            players : []
        }

    }

    componentDidMount(){
        if(Platform.OS != 'ios'){
            return;
        }
        NativeModules.EaseMessageViewManager.joinChannel("test")
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
                if(index>0){
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
        this.firstRemoteVideoDecoded_subscription.remove();
    }

    render(){
        return (
            <View style={styles.container}>
                <WhiteSpace size="lg"/>
                <Text>球队，联盟，好友，关注，消息等</Text>
                <View style={{flex:1,position:"relative"}}>
                    <View style={{position:"absolute",marginLeft:70,top:0,width:20,height:20,backgroundColor:'blue',transform:[{
                        rotate:"45deg"
                    }]}}></View>
                    <View style={{width:100,height:100,backgroundColor:'blue'}}></View>
                    <EaseMessageView uid={0} style={{width:60,height:90}}/>
                    {
                        this.state.players.map((item)=>{
                            return <View>
                                <WhiteSpace/>
                                <EaseMessageView uid={item} style={{width:60,height:90}}/>
                            </View>
                        })
                    }
                </View>

            </View>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        //alignItems:'center',
        //justifyContent:'center'
    },
    icon:{
        width:32,
        height:32
    }
})