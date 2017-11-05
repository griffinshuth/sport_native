import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text
} from 'react-native'

import {NavigationActions} from 'react-navigation'
import {connect} from 'dva'

@connect()
export default class Tab3Page extends Component{
    static navigationOptions = {
        tabBarLabel:'比赛',
        tabBarIcon: ({ focused, tintColor }) =>
            <Image
                style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                source={require('../../assets/images/match.png')}
            />,
    }

    render(){
        return (
            <View style={styles.container}>
                <Text>比赛创建和管理</Text>
            </View>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        alignItems:'center',
        justifyContent:'center'
    },
    icon:{
        width:32,
        height:32
    }
})