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

import {
    WhiteSpace,
    Toast,
    Button
} from 'antd-mobile'

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
    }

    componentDidMount(){

    }

    componentWillUnmount(){

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