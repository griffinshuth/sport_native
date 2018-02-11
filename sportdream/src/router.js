import {
    StackNavigator,
    addNavigationHelpers
} from 'react-navigation'

import {
    Toast
} from 'antd-mobile'

import {get,post} from './fetch.js'

import React,{Component} from 'react'
import {
    BackHandler,
    Animated,Easing,
    View,
    Text,
    StyleSheet,
    ActivityIndicator
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
import ReactArtTest from './pages/test/ReactArtTest'
import BarCodeTest from './pages/test/BarCodeTest'
import QrCodeTest from './pages/test/QrCodeTest'
import SocketIOTest from './pages/test/SocketIOTest'
import CreateStreetMatch from './pages/match/CreateStreetMatch'
import CreateWiFiAP from './pages/WiFi/CreateWiFiAP'
import MatchDetail from './pages/match/MatchDetail'
import CreateTempTeam from './pages/match/CreateTempTeam'
import match_admin from './pages/match/match_admin'
import ShootPoint from './pages/match/ShootPoint'
import match_watch from './pages/match/match_watch'
import createTeamLogoName from './pages/match/createTeamLogoName'
import MatchGameList from './pages/match/MatchGameList'
import Scoreboard from './pages/match/Scoreboard'
import substitution from'./pages/match/substitution'
import TeamShootPoint from './pages/match/TeamShootPoint'
import ShootTrain from './pages/test/ShootTrain'
import QiniuLiveTest from './pages/test/QiniuLiveTest'
import QiniuPlayTest from './pages/test/QiniuPlayTest'
import AgoraChatTest from './pages/test/AgoraChatTest'
import AgoraChat_AndroidTest from './pages/test/AgoraChat_AndroidTest'

const AppNavigator = StackNavigator(
    {
        index:{screen:IndexPage},
        Count:{screen:CountPage},
        Demo:{screen:DemoPage},
        BTDiscover:{screen:BTDiscoverPage},
        BLEPage:{screen:BLEPage},
        BluetoothCrossPlatform:{screen:BluetoothCrossPlatform},
        ReactArtTest:{screen:ReactArtTest},
        BarCodeTest:{screen:BarCodeTest},
        QrCodeTest:{screen:QrCodeTest},
        SocketIOTest:{screen:SocketIOTest},
        CreateStreetMatch:{screen:CreateStreetMatch},
        CreateWiFiAP:{screen:CreateWiFiAP},
        MatchDetail:{screen:MatchDetail},
        CreateTempTeam:{screen:CreateTempTeam},
        match_admin:{screen:match_admin},
        ShootPoint:{screen:ShootPoint},
        match_watch:{screen:match_watch},
        createTeamLogoName:{screen:createTeamLogoName},
        MatchGameList:{screen:MatchGameList},
        Scoreboard:{screen:Scoreboard},
        substitution:{screen:substitution},
        TeamShootPoint:{screen:TeamShootPoint},
        ShootTrain:{screen:ShootTrain},
        QiniuLiveTest:{screen:QiniuLiveTest},
        QiniuPlayTest:{screen:QiniuPlayTest},
        AgoraChatTest:{screen:AgoraChatTest},
        AgoraChat_AndroidTest:{screen:AgoraChat_AndroidTest},
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
    constructor(props){
        super(props);
    }

    getMyInfo = async (token)=>{
        var result = await get("/getUserInfo",{token:token})
        return result;
    }

    componentWillReceiveProps(nextProps){

    }

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
            return <View style={styles.container}><ActivityIndicator/></View>
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