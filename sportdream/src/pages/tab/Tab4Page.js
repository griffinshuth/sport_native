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

import ToolBar from '../../Components/ToolBar'
import {NavigationActions} from 'react-navigation'
import {connect} from 'dva'

@connect()
export default class Tab4Page extends Component{
    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="教学" navigation={this.props.navigation}/>
                <View style={styles.container}>
                    <Text>力量训练，投篮，三步上篮，防守步法，吹罚规则等</Text>
                </View>
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