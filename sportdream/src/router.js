import {
    StackNavigator,
    addNavigationHelpers
} from 'react-navigation'

import React,{Component} from 'react'
import {
    BackHandler,
    Animated,Easing,
    View,
    Text,
    StyleSheet
} from 'react-native'
import {connect} from 'dva'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import IndexPage from './pages/IndexPage'
import CountPage from './pages/test/CountPage'
import DemoPage from './pages/test/DemoPage'
import BTDiscoverPage from './pages/test/BTDiscover'
import BLEPage from './pages/test/BLEPage'
import BluetoothCrossPlatform from './pages/test/BluetoothCrossPlatform'

const AppNavigator = StackNavigator(
    {
        index:{screen:IndexPage},
        Count:{screen:CountPage},
        Demo:{screen:DemoPage},
        BTDiscover:{screen:BTDiscoverPage},
        BLEPage:{screen:BLEPage},
        BluetoothCrossPlatform:{screen:BluetoothCrossPlatform},
    },
    {
        headerMode: 'none',
        navigationOptions:{
            gesturesEnabled:true
        }
    }
)

const LoginNavigator = StackNavigator(
    {
        Login:{screen:LoginPage},
        Register:{screen:RegisterPage}
    },
    {
        navigationOptions:{
            gesturesEnabled:true
        }
    }
)

@connect(({router,appNS,temp})=>({router,appNS,temp}))
export default class Router extends Component{
    render(){
        const {dispatch,router,appNS,temp} = this.props;
        const navigation = addNavigationHelpers({dispatch,state:router});
        if(temp.loadfromstore){
            if(appNS.token){
                return <AppNavigator navigation={navigation} />
            }else{
                return <LoginNavigator/>
            }
        }else{
            return <View style={styles.container}><Text>进场动画</Text></View>
        }
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        alignItems:'center',
        justifyContent:'center'
    }
})

export function routerReducer(state,action={}){
    return AppNavigator.router.getStateForAction(action,state);
}