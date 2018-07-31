import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text
} from 'react-native'
import {
    Button
} from 'antd-mobile'

import {NavigationActions} from 'react-navigation'
import {connect} from 'dva'

@connect()
export default class Tab4Page extends Component{
    static navigationOptions = {
        tabBarLabel:'基本功',
        tabBarIcon: ({ focused, tintColor }) =>
            <Image
                style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                source={require('../../assets/images/shoot.png')}
            />,
    }

    render(){
        return (
            <View style={styles.container}>
                <Text>力量训练，投篮，三步上篮，防守步法，吹罚规则等</Text>
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