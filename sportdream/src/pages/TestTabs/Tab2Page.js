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
import ToolBar from '../../Components/ToolBar'

import {connect} from 'dva'
import {
    NavigationActions,
    StackNavigator,
    addNavigationHelpers
} from 'react-navigation'

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

    gotoShootMatchListPage = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'ShootMatchListPage'}))
    }

    render(){
        return (
            <View style={styles.container}>
                <ToolBar
                    title="投篮训练"
                    navigation={this.props.navigation}
                     />
                <WhiteSpace size="lg"/>
                <Button>投篮训练</Button>
                <WhiteSpace/>
                <Button onClick={this.gotoShootMatchListPage}>远程投篮比赛</Button>
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