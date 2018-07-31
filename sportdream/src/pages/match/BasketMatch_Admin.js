import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    Image,
    TouchableHighlight,
    ScrollView,
    StyleSheet,
    NativeEventEmitter,
    NativeModules,
    requireNativeComponent
} from 'react-native'

import {
    Button,
    WhiteSpace,
    WingBlank,
    Toast,
    Flex,
    Card,
    ActionSheet,
    List,
    Modal,
    ActivityIndicator,
    Badge,
    Slider,
    NoticeBar
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
//var RemoteControlView = requireNativeComponent('RemoteControlView', null);
var LocalClientModule = NativeModules.LocalClientModule;
const LocalClientModuleEmitter = new NativeEventEmitter(LocalClientModule);

import BasketMatch_Timer from "../../Components/BasketMatch_Admin/BasketMatch_Timer"
import CurrentBasketMatchTeam from "../../Components/BasketMatch_Admin/CurrentBasketMatchTeam"
import BasketMatch_SectionTime from "../../Components/BasketMatch_Admin/BasketMatch_SectionTime"
import JSONPacketStruct from "../../utils/JSONPacketStruct";

const styles = StyleSheet.create({
    container:{
        flex:1
    },
    comment:{
        backgroundColor:'white',borderWidth:1,borderColor:'#ccc',borderRadius:5
    },
})

@connect(({appNS,user,CurrentAdminMatchModel,temp})=>({appNS,user,CurrentAdminMatchModel,temp}))
export default class App extends React.Component{
    loadFromServer = async()=>{
        var game_uid = this.props.navigation.state.params.game_uid;
        var team1PlayerUids = this.props.navigation.state.params.team1.members;
        var team2PlayerUids = this.props.navigation.state.params.team2.members;
        this.props.dispatch({type:"CurrentAdminMatchModel/loadFromServer",payload:{
            game_uid:game_uid,
            team1PlayerUids:team1PlayerUids,
            team2PlayerUids:team2PlayerUids
        }})
        /*var gameinfo = await post("/getGameInfo",{game_uid:game_uid});
        if(gameinfo.team1Player.length == 0){
            var admin_result = await post("/adminGame",{
                game_uid:game_uid,
                optype:admin_op.insquad,
                meta:{players:team1PlayerUids,teamindex:0}
            });
            gameinfo.team1Player = admin_result.team1Player //该字段存储的是队伍1的大名单，类型是数组，里面的元素是唯一ID
            //设置首发
            var startLineUp = [];
            for(var i=0;i<5;i++){
                startLineUp.push(gameinfo.team1Player[i])
            }
            var admin_result = await post("/adminGame",{
                game_uid:game_uid,
                optype:admin_op.startup,
                meta:{players:startLineUp,teamindex:0}
            });
            gameinfo.team1Startup = admin_result.team1Startup; //队伍1首发数组，元素类型是唯一ID
            gameinfo.roomInfo.team1currentplayers = admin_result.team1currentplayers; //队伍1当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
        }
        if(gameinfo.team2Player.length == 0){
            var admin_result = await post("/adminGame",{
                game_uid:game_uid,
                optype:admin_op.insquad,
                meta:{players:team2PlayerUids,teamindex:1}
            });
            gameinfo.team2Player = admin_result.team2Player  //该字段存储的是队伍2的大名单，类型是数组，里面的元素是唯一ID
            //设置首发
            var startLineUp = [];
            for(var i=0;i<5;i++){
                startLineUp.push(gameinfo.team2Player[i])
            }
            var admin_result = await post("/adminGame",{
                game_uid:game_uid,
                optype:admin_op.startup,
                meta:{players:startLineUp,teamindex:1}
            });
            gameinfo.team2Startup = admin_result.team2Startup; //队伍2首发数组，元素类型是唯一ID
            gameinfo.roomInfo.team2currentplayers = admin_result.team2currentplayers; //队伍2当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
        }
        //获得两队队员的详细信息，并缓存起来
        var allTeam1PLayers = await post("/getPlayerInfosOfUids",{uids:gameinfo.team1Player});
        var allTeam2Players = await post("/getPlayerInfosOfUids",{uids:gameinfo.team2Player});

        //设置用户唯一ID和对应数据的map
        var ID2DataMap = {};
        for(var i in allTeam1PLayers.players){
            var uid = allTeam1PLayers.players[i].id;
            ID2DataMap[uid] = allTeam1PLayers.players[i];
        }
        for(var i in allTeam2Players.players){
            var uid = allTeam2Players.players[i].id;
            ID2DataMap[uid] = allTeam2Players.players[i];
        }

        var team1Members = [];
        var members1OffCourt = [];
        for(var i=0;i<gameinfo.team1Player.length;i++){
            var uid = gameinfo.team1Player[i]
            var isPLayerInCourt = false;
            for(var t=0;t<gameinfo.roomInfo.team1currentplayers.length;t++){
                if(uid == gameinfo.roomInfo.team1currentplayers[t].uid){
                    isPLayerInCourt = true;
                }
            }
            if(isPLayerInCourt){
                team1Members.push(ID2DataMap[uid])
            }else{
                members1OffCourt.push(ID2DataMap[uid])
            }
        }

        var team2Members = [];
        var members2OffCourt = [];
        for(var i=0;i<gameinfo.team2Player.length;i++){
            var uid = gameinfo.team2Player[i]
            var isPLayerInCourt = false;
            for(var t=0;t<gameinfo.roomInfo.team2currentplayers.length;t++){
                if(uid == gameinfo.roomInfo.team2currentplayers[t].uid){
                    isPLayerInCourt = true;
                }
            }
            if(isPLayerInCourt){
                team2Members.push(ID2DataMap[uid])
            }else{
                members2OffCourt.push(ID2DataMap[uid])
            }
        }

        var team1dataStatistics = {};
        for(var i=0;i<gameinfo.team1Player.length;i++){
            var uid = gameinfo.team1Player[i];
            team1dataStatistics[uid] = gameinfo.roomInfo[uid];
        }
        var team2dataStatistics = {};
        for(var i=0;i<gameinfo.team2Player.length;i++){
            var uid = gameinfo.team2Player[i];
            team2dataStatistics[uid] = gameinfo.roomInfo[uid];
        }

        var final_state = {
            game_uid:game_uid,
            team1Members:team1Members,
            team2Members:team2Members,
            members1OffCourt:members1OffCourt,
            members2OffCourt:members2OffCourt,
            team1dataStatistics:team1dataStatistics,
            team2dataStatistics:team2dataStatistics,
            ballowner:gameinfo.roomInfo.ballowner,
            currentattacktime:gameinfo.roomInfo.currentattacktime,
            currentsection:gameinfo.roomInfo.currentsection,
            currentsectiontime:gameinfo.roomInfo.currentsectiontime,
            team1currentscore:gameinfo.roomInfo.team1currentscore,
            team2currentscore:gameinfo.roomInfo.team2currentscore,
            team1timeout:gameinfo.roomInfo.team1timeout,
            team2timeout:gameinfo.roomInfo.team2timeout
        }
        this.props.dispatch({type:'CurrentAdminMatchModel/init',payload:final_state})*/

    }
    loadSilenceSound = ()=>{

    }
    unloadSilenceSound = ()=>{

    }
    componentDidMount(){
        if(!this.props.temp.isOffline){
            this.loadFromServer();
        }else{
            this.props.dispatch({type:"CurrentAdminMatchModel/init",payload:{}})
        }
        this.loadSilenceSound();
        this.serverDiscovered_handler = LocalClientModuleEmitter.addListener("serverDiscovered",this.serverDiscovered);
        this.clientReceiveData_handler = LocalClientModuleEmitter.addListener("clientReceiveData",this.clientReceiveData);
        this.clientSocketConnected_handler = LocalClientModuleEmitter.addListener("clientSocketConnected",this.clientSocketConnected);
        this.clientSocketDisconnect_handler = LocalClientModuleEmitter.addListener("clientSocketDisconnect",this.clientSocketDisconnect);
        LocalClientModule.startClient(8888,6666);
    }
    componentWillUnmount(){
        this.props.dispatch({type:'CurrentAdminMatchModel/destroy'})
        this.unloadSilenceSound();
        this.serverDiscovered_handler.remove();
        this.clientReceiveData_handler.remove();
        this.clientSocketConnected_handler.remove();
        this.clientSocketDisconnect_handler.remove();
        LocalClientModule.stopClient();
    }
    componentWillReceiveProps(){

    }
    //连接导播服务器的网络客户端begin
    search = ()=>{
        LocalClientModule.searchServer();
    }
    sendToDirectServer = (json)=>{
        var str = JSON.stringify(json);
        LocalClientModule.clientSend(str);
    }
    serverDiscovered = ()=>{
        Toast.info("server discovered",1)
    }
    clientReceiveData = (result)=>{
        Toast.info(result);
    }
    clientSocketConnected = ()=>{
        var clientID = this.props.appNS.clientID;
        var json = JSONPacketStruct.matchDataLogin(clientID);
        this.sendToDirectServer(json);
    }
    clientSocketDisconnect = ()=>{

    }
    uploadDataToDirectServer = ()=>{
        var result = {};
        result.game_uid = this.props.CurrentAdminMatchModel.game_uid;
        result.team1Members = this.props.CurrentAdminMatchModel.team1Members;
        result.team2Members = this.props.CurrentAdminMatchModel.team2Members;
        result.members1OffCourt = this.props.CurrentAdminMatchModel.members1OffCourt;
        result.members2OffCourt = this.props.CurrentAdminMatchModel.members2OffCourt;
        result.ballowner = this.props.CurrentAdminMatchModel.ballowner;
        result.currentattacktime = this.props.CurrentAdminMatchModel.currentattacktime;
        result.currentsection = this.props.CurrentAdminMatchModel.currentsection;
        result.currentsectiontime = this.props.CurrentAdminMatchModel.currentsectiontime;
        result.team1currentscore = this.props.CurrentAdminMatchModel.team1currentscore;
        result.team2currentscore = this.props.CurrentAdminMatchModel.team2currentscore;
        result.team1timeout = this.props.CurrentAdminMatchModel.team1timeout;
        result.team2timeout = this.props.CurrentAdminMatchModel.team2timeout;
        result.team1dataStatistics = this.props.CurrentAdminMatchModel.team1dataStatistics;
        result.team2dataStatistics = this.props.CurrentAdminMatchModel.team2dataStatistics;
        result.team1info = this.props.navigation.state.params.team1;
        result.team2info = this.props.navigation.state.params.team2;
        var json = {id:"uploadDataToDirectServer",data:result}
        this.sendToDirectServer(json);
    }
    //连接导播服务器的网络客户端end
    //蓝牙耳机操作处理函数
    remoteControlCommand = (event)=>{
        //Toast.info(JSON.stringify(event.nativeEvent));
        if(event.nativeEvent.type == "Play" || event.nativeEvent.type == "TogglePlayPause"){
            const {
                isTimerStart,
            } = this.props.CurrentAdminMatchModel;
            if(!isTimerStart)
                this.props.dispatch({type:"CurrentAdminMatchModel/timestart",payload:{isTimerStart:true}})
            else{
                this.props.dispatch({type:"CurrentAdminMatchModel/timestart",payload:{isTimerStart:false}})
            }
        }
    }

    //子组件回调函数
    startCountDownFromParent = ()=>{
        if(this.props.CurrentAdminMatchModel.isTimerStart){
            Toast.info("倒计时已经开始",1);
            return;
        }
        if(this.props.CurrentAdminMatchModel.currentattacktime == 0){
            //24秒为零，需要用户重置24秒
            Toast.info("请重置24秒",1);
            return;
        }
        if(this.props.CurrentAdminMatchModel.currentsection == 4 && this.props.CurrentAdminMatchModel.currentsectiontime == 0){
            //比赛结束
            Toast.info("比赛已经结束",1);
            return;
        }
        if(this.props.CurrentAdminMatchModel.currentsectiontime == 0){
            Modal.alert('本节结束', '是否进入下一节', [
                { text: '否', onPress: () => {} },
                { text: '是', onPress: () => {
                    this.props.dispatch({type:"CurrentAdminMatchModel/nextSection",payload:{}})
                    this.props.dispatch({type:"CurrentAdminMatchModel/nextSectionUpdateServer",payload:{
                        currentsection:this.props.CurrentAdminMatchModel.currentsection,
                        game_uid:this.props.CurrentAdminMatchModel.game_uid
                    }})
                } },
            ])
            return;
        }
        this.props.dispatch({type:"CurrentAdminMatchModel/timestart",payload:{isTimerStart:true}})
    }

    render(){
        var team1info = this.props.navigation.state.params.team1;
        var team2info = this.props.navigation.state.params.team2;
        const {
            loading,
            team1Members,
            team2Members,
            members1OffCourt,
            members2OffCourt,
            isTimerStart,
            ballowner,
            currentattacktime,
            currentsection,
            currentsectiontime,
            team1currentscore,
            team2currentscore,
            team1timeout,
            team2timeout,
            team1dataStatistics,
            team2dataStatistics,
            need01
        } = this.props.CurrentAdminMatchModel;

        var SectionTime_Props = null;
        var MatchTimer_Props = null;
        var CurrentMatchTeam1_Props = null;
        var CurrentMatchTeam2_Props = null;

        if(!loading){
            SectionTime_Props = {
                game_uid:this.props.CurrentAdminMatchModel.game_uid,
                currentsectiontime:currentsectiontime,
                currentsection:currentsection,
                currentattacktime:currentattacktime,
            }
            MatchTimer_Props  = {
                game_uid:this.props.CurrentAdminMatchModel.game_uid,
                isTimerStart:isTimerStart,
                team1info:team1info,
                team2info:team2info,
                ballowner:ballowner,
                need01:need01,
                currentsectiontime:currentsectiontime,
                currentattacktime:currentattacktime,
                dispatch:this.props.dispatch,
                startCountDownFromParent:this.startCountDownFromParent
            }

            CurrentMatchTeam1_Props = {
                game_uid:this.props.CurrentAdminMatchModel.game_uid,
                teamindex:0,
                teaminfo:team1info,
                teamcurrentscore:team1currentscore,
                teamMembers:team1Members,
                membersOffCourt:members1OffCourt,
                ballowner:ballowner,
                teamtimeout:team1timeout,
                teamdataStatistics:team1dataStatistics,
                dispatch:this.props.dispatch,
                navigation:this.props.navigation
            }

            CurrentMatchTeam2_Props = {
                game_uid:this.props.CurrentAdminMatchModel.game_uid,
                teamindex:1,
                teaminfo:team2info,
                teamcurrentscore:team2currentscore,
                teamMembers:team2Members,
                membersOffCourt:members2OffCourt,
                ballowner:ballowner,
                teamtimeout:team2timeout,
                teamdataStatistics:team2dataStatistics,
                dispatch:this.props.dispatch,
                navigation:this.props.navigation
            }
        }
        return (
            <View style={styles.container}>
                <ToolBar title="技术统计" navigation={this.props.navigation} />
                {loading?<ActivityIndicator/>:<ScrollView style={styles.container}>
                    {this.props.temp.isOffline?<NoticeBar mode="" onClick={()=>{Toast.info("重连服务器...")}} icon={null}>离线模式(点击重连)</NoticeBar>:null}
                    <WingBlank>
                        {/*<RemoteControlView onChange={this.remoteControlCommand}/>*/}
                        <WhiteSpace/>
                        {<CurrentBasketMatchTeam {...CurrentMatchTeam1_Props} />}
                        <WhiteSpace size="xs"/>
                        <BasketMatch_SectionTime {...SectionTime_Props}/>
                        <BasketMatch_Timer {...MatchTimer_Props} />
                        <WhiteSpace/>
                        <Button onClick={this.search}>连接导播服务器</Button>
                        <Button onClick={this.uploadDataToDirectServer}>同步技术统计</Button>
                        <WhiteSpace size="xs"/>
                        {<CurrentBasketMatchTeam {...CurrentMatchTeam2_Props} />}
                        <WhiteSpace/>
                    </WingBlank>
                </ScrollView>}
            </View>
        )
    }
}
