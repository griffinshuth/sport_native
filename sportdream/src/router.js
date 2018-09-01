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
    ActivityIndicator,
    AppState,
    Platform
} from 'react-native'
import nodejs from 'nodejs-mobile-react-native'
import BleManager from 'react-native-ble-manager';
BleManager.start({showAlert: false});

import {connect} from 'dva'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import IndexPage from './pages/IndexPage'
import CountPage from './pages/test/CountPage'
import DemoPage from './pages/test/DemoPage'
import BTDiscoverPage from './pages/test/BTDiscover'
import BLEPage from './pages/test/BLEPage'
import BLEPeripheralTest from './pages/test/BLEPeripheralTest'
import BluetoothCrossPlatform from './pages/test/BluetoothCrossPlatform'
import ReactArtTest from './pages/test/ReactArtTest'
import BarCodeTest from './pages/test/BarCodeTest'
import QrCodeTest from './pages/test/QrCodeTest'
import CreateStreetMatch from './pages/match/CreateStreetMatch'
import CreateWiFiAP from './pages/WiFi/CreateWiFiAP'
import MatchDetail from './pages/match/MatchDetail'
import CreateTempTeam from './pages/match/CreateTempTeam'
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
import VoiceCount from "./pages/test/VoiceCount"
import BasketMatch_Admin from './pages/match/BasketMatch_Admin'
import ReactNativeCameraTest from './pages/test/ReactNativeCameraTest'
import ReactNativeVideoTest from './pages/test/ReactNativeVideoTest'
import LocalClientTest from './pages/test/LocalClientTest'
import LocalServerTest from './pages/test/LocalServerTest'
import highlightServer from './pages/test/highlightServer'
import bleP2PTest from './pages/test/bleP2PTest'
import SmartBasketballStand from './pages/test/SmartBasketballStand'
import ShootMatchListPage from './pages/shoot/ShootMatchListPage'
import CreateShootMatchPage from './pages/shoot/CreateShootMatchPage'
import NormalBasketCourtShootRoom from './pages/shoot/NormalBasketCourtShootRoom'
import SmartBasketStandShootRoom from './pages/shoot/SmartBasketStandShootRoom'
import BasketCourtShootRoomAndroid from './pages/shoot/BasketCourtShootRoomAndroid'
import CreateTimeLinePage from './pages/Social/CreateTimeLinePage'
import TimeLinePage from './pages/Social/TimeLinePage'
import NearbyUsers from './pages/Social/NearbyUsers'
import otherUserDetails from './pages/Social/otherUserDetails'

const AppNavigator = StackNavigator(
    {
        index:{screen:IndexPage},
        Count:{screen:CountPage},
        Demo:{screen:DemoPage},
        BTDiscover:{screen:BTDiscoverPage},
        BLEPage:{screen:BLEPage},
        BLEPeripheralTest:{screen:BLEPeripheralTest},
        BluetoothCrossPlatform:{screen:BluetoothCrossPlatform},
        ReactArtTest:{screen:ReactArtTest},
        BarCodeTest:{screen:BarCodeTest},
        QrCodeTest:{screen:QrCodeTest},
        CreateStreetMatch:{screen:CreateStreetMatch},
        CreateWiFiAP:{screen:CreateWiFiAP},
        MatchDetail:{screen:MatchDetail},
        CreateTempTeam:{screen:CreateTempTeam},
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
        BasketMatch_Admin:{screen:BasketMatch_Admin},
        VoiceCount:{screen:VoiceCount},
        ReactNativeCameraTest:{screen:ReactNativeCameraTest},
        ReactNativeVideoTest:{screen:ReactNativeVideoTest},
        LocalClientTest:{screen:LocalClientTest},
        LocalServerTest:{screen:LocalServerTest},
        highlightServer:{screen:highlightServer},
        bleP2PTest:{screen:bleP2PTest},
        SmartBasketballStand:{screen:SmartBasketballStand},
        ShootMatchListPage:{screen:ShootMatchListPage},
        CreateShootMatchPage:{screen:CreateShootMatchPage},
        NormalBasketCourtShootRoom:{screen:NormalBasketCourtShootRoom},
        SmartBasketStandShootRoom:{screen:SmartBasketStandShootRoom},
        BasketCourtShootRoomAndroid:{screen:BasketCourtShootRoomAndroid},
        CreateTimeLinePage:{screen:CreateTimeLinePage},
        TimeLinePage:{screen:TimeLinePage},
        NearbyUsers:{screen:NearbyUsers},
        otherUserDetails:{screen:otherUserDetails},
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

    componentWillReceiveProps(nextProps){

    }

    componentWillMount()
    {
        if(Platform.OS == 'ios'){
            var version = Platform.Version;
            var arr = version.split('.');
            if(arr[0] != 8){
                nodejs.start('main.js');
                this.listenerRef = ((msg) => {
                    alert(msg);
                });
                nodejs.channel.addListener(
                    'message',
                    this.listenerRef,
                    this
                );
            }
        }

        if(Platform.OS == 'android') {
            if (Platform.Version >= 21) {
                nodejs.start('main.js');
                this.listenerRef = ((msg) => {
                    alert(msg);
                });
                nodejs.channel.addListener(
                    'message',
                    this.listenerRef,
                    this
                );
            }
        }
    }
    componentWillUnmount()
    {
        if(Platform.OS == 'ios'){
            var version = Platform.Version;
            var arr = version.split('.');
            if(arr[0] != 8){
                if (this.listenerRef) {
                    nodejs.channel.removeListener('message', this.listenerRef);
                }
            }
        }

        if(Platform.OS == 'android') {
            if (Platform.Version >= 21) {
                if (this.listenerRef) {
                    nodejs.channel.removeListener('message', this.listenerRef);
                }
            }
        }
    }
    componentDidMount(){
        if(Platform.OS == 'ios'){
            var version = Platform.Version;
            var arr = version.split('.');
            if(arr[0] != 8){
                AppState.addEventListener('change', (state) => {
                    if (state === 'active') {
                        nodejs.channel.send('resume');
                    }
                    if (state === 'background') {
                        nodejs.channel.send('suspend');
                    }
                });
            }
        }

        if(Platform.OS == 'android') {
            if (Platform.Version >= 21) {
                AppState.addEventListener('change', (state) => {
                    if (state === 'active') {
                        nodejs.channel.send('resume');
                    }
                    if (state === 'background') {
                        nodejs.channel.send('suspend');
                    }
                });
            }
        }
        this.timer = setInterval(()=>{
            if(this.props.temp.loadfromstore){
                clearInterval(this.timer);
                if(this.props.appNS.token){
                    this.props.dispatch({type:'user/getUserInfo',payload:{token:this.props.appNS.token}})
                }
            }
        },20)
    }

    render(){
        const {dispatch,router,appNS,temp} = this.props;
        const navigation = addNavigationHelpers({dispatch,state:router});

        if(temp.loadfromstore){
            if(appNS.token){
                if(temp.isOffline){
                    //Toast.info("offline");
                    return <AppNavigator navigation={navigation} />
                }
                if(!temp.isServerConnected){
                    return <View style={styles.container}><ActivityIndicator/></View>
                }
                if(!temp.tokenExpired){
                    return <AppNavigator navigation={navigation} />
                }else{
                    return <LoginNavigator/>
                }
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