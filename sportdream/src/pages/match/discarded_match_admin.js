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
    NativeModules
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
    Slider
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {get, post,serverurl} from '../../fetch'
import io from 'socket.io-client'
import {clientEvent,serverEvent,permissionType,admin_op} from '../../utils/socketEvent'
import emitter from '../../utils/SingleEventEmitter'

//component
import MatchTimer from '../../Components/Match_Timer'
import CurrentMatchTeam from '../../Components/CurrentMatchTeam'

const styles = StyleSheet.create({
    playerdata:{
        color:'#ccc',
        fontSize:10,
        lineHeight:16,
        width:16,
        height:16,
        borderWidth:1,
        borderColor:'#eee',
        textAlign:'center',
        borderRadius:8,
    },
    container:{
        flex:1
    },
    teamlogo:{
        width:32,height:32
    },
    teamname:{
        marginLeft:10
    },
    teamstate:{
        marginLeft:10,color:'red',fontWeight:"bold",fontSize:20
    },
    card_background:{
        backgroundColor:'white'
    },
    data_button:{
        marginLeft:5,height:30
    },
    player_flex_item:{
        alignItems:"center"
    },
    player_image:{
        width:44,height:54,borderRadius:10,borderColor:'blue',borderWidth:1
    },
    comment:{
        backgroundColor:'white',borderWidth:1,borderColor:'#ccc',borderRadius:5
    },
    time_font:{
        fontSize:20,fontWeight:"bold"
    }
})

@connect(({appNS,user})=>({appNS,user}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            modelvisible:false,
            loading:true,
            game_uid : this.props.navigation.state.params.game_uid,
            team1Members:[],  //场上球员列表
            team2Members:[],  //场上球员列表
            members1OffCourt:[], //场下球员列表
            members2OffCourt:[], //场下球员列表
            gameInfo:null,
            isTimerStart:false,
            stateOfMatch:"",  //未开赛，进行中，节间休息，中场休息，完赛
            brightness:0.5,
        }
    }

    isBonus = (team)=>{
        if(team == 0){
            var players = this.state.gameInfo.team1Player;
        }else{
            var players = this.state.gameInfo.team2Player;
        }
            var currentsection = this.state.gameInfo.roomInfo.currentsection;
            var total = 0;
            for(var i=0;i<players.length;i++){
                var uid = players[i];
                if(this.state.gameInfo.roomInfo[uid]){
                    var fouls = this.state.gameInfo.roomInfo[uid]["foul"];
                    if(fouls){
                        for(var f in fouls){
                            if(fouls[f].section == currentsection){
                                total++;
                            }
                        }
                    }
                }
            }
            if(total>4){
                return true;
            }else{
                return false;
            }
    }

    gotoTeamShootPoint = ()=>{
        var data = {}
        for(var i=0;i<this.state.gameInfo.team1Player.length;i++){
            var uid = this.state.gameInfo.team1Player[i];
            data[uid] = {};
            if(!this.state.gameInfo.roomInfo[uid]){
                this.state.gameInfo.roomInfo[uid] = {};
            }
            if(!this.state.gameInfo.roomInfo[uid]["shoot"]){
                data[uid]["shoot"] = [];
            }else{
                data[uid]["shoot"] = this.state.gameInfo.roomInfo[uid]["shoot"].map((item)=>{return item})
            }
            if(!this.state.gameInfo.roomInfo[uid]["freethrow"]){
                data[uid]["freethrow"] = [];
            }else{
                data[uid]["freethrow"] = this.state.gameInfo.roomInfo[uid]["freethrow"].map((item)=>{return item})
            }
        }

        for(var i=0;i<this.state.gameInfo.team2Player.length;i++){
            var uid = this.state.gameInfo.team2Player[i];
            data[uid] = {};
            if(!this.state.gameInfo.roomInfo[uid]){
                this.state.gameInfo.roomInfo[uid] = {};
            }
            if(!this.state.gameInfo.roomInfo[uid]["shoot"]){
                data[uid]["shoot"] = [];
            }else{
                data[uid]["shoot"] = this.state.gameInfo.roomInfo[uid]["shoot"].map((item)=>{return item})
            }
            if(!this.state.gameInfo.roomInfo[uid]["freethrow"]){
                data[uid]["freethrow"] = [];
            }else{
                data[uid]["freethrow"] = this.state.gameInfo.roomInfo[uid]["freethrow"].map((item)=>{return item})
            }
        }

        this.props.navigation.navigate("TeamShootPoint",{
            team1Members:this.state.team1Members,
            team2Members:this.state.team2Members,
            playerData : data,
            setPermission:this.setPermission,
            unsetPermission:this.unsetPermission,
        })
    }

    adminGame = async()=>{
        var clientID = this.props.appNS.clientID;
        var token = this.props.appNS.token;
        console.log(this.props.user.uid);
        var uid = this.props.user.uid;

        this.socket = io(serverurl,{
            //transports: ['websocket'],
        });
        this.socket.on("reconnect",()=>{
            console.log("reconnect")
        })
        /*this.socket.on(clientEvent.initRoomInfo,(data)=>{
            console.log("initRoomInfo:",data);
            this.setState({roominfo:data})
        })*/
        this.socket.emit(serverEvent.login,{uuid:uid,clientID:clientID},(data)=>{
            console.log(data);
            var room_uid = this.props.navigation.state.params.room_uid;
            console.log(this.props.navigation.state.params);
            this.socket.emit(serverEvent.enterRoom,{room_uid:room_uid},(data)=>{
                console.log("enterRoom:",data);
                //设置权限
                var permissions = [];
                for(var i in permissionType){
                    if(permissionType[i]!=permissionType.updateShoot && permissionType[i] != permissionType.updateFreethrow){
                        permissions.push(permissionType[i]);
                    }
                }
                this.socket.emit(serverEvent.setPermission,{permissions:permissions},async(data)=>{
                    console.log("setPermission:",data);
                    //读取房间信息
                    var game_uid = this.props.navigation.state.params.game_uid;
                    var gameinfo = await post("/getGameInfo",{game_uid:game_uid});
                    console.log("before:",gameinfo);
                    //设置大名单
                    var team1 = this.props.navigation.state.params.team1.members;
                    var team2 = this.props.navigation.state.params.team2.members;
                    if(gameinfo.team1Player.length == 0){
                        var admin_result = await post("/adminGame",{
                            game_uid:game_uid,
                            optype:admin_op.insquad,
                            meta:{players:team1,teamindex:0}
                        })
                        console.log("insquad:",admin_result)
                        if(!admin_result.error)
                            gameinfo.team1Player = admin_result.team1Player //该字段存储的是队伍1的大名单，类型是数组，里面的元素是唯一ID
                        else{
                            Toast.info(admin_result.errorinfo)
                            return;
                        }
                        //设置首发
                        var startLineUp = [];
                        for(var i=0;i<5;i++){
                            startLineUp.push(gameinfo.team1Player[i])
                        }
                        var admin_result = await post("/adminGame",{
                            game_uid:game_uid,
                            optype:admin_op.startup,
                            meta:{players:startLineUp,teamindex:0}
                        })
                        console.log("insquad:",admin_result)
                        gameinfo.team1Startup = admin_result.team1Startup; //队伍1首发数组，元素类型是唯一ID
                        gameinfo.roomInfo.team1currentplayers = admin_result.team1currentplayers; //队伍1当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
                    }
                    if(gameinfo.team2Player.length == 0){
                        var admin_result = await post("/adminGame",{
                            game_uid:game_uid,
                            optype:admin_op.insquad,
                            meta:{players:team2,teamindex:1}
                        })
                        console.log("insquad:",admin_result)
                        if(!admin_result.error)
                            gameinfo.team2Player = admin_result.team2Player  //该字段存储的是队伍2的大名单，类型是数组，里面的元素是唯一ID
                        else{
                            Toast.info(admin_result.errorinfo)
                            return;
                        }
                        //设置首发
                        var startLineUp = [];
                        for(var i=0;i<5;i++){
                            startLineUp.push(gameinfo.team2Player[i])
                        }
                        var admin_result = await post("/adminGame",{
                            game_uid:game_uid,
                            optype:admin_op.startup,
                            meta:{players:startLineUp,teamindex:1}
                        })
                        console.log("insquad:",admin_result)
                        gameinfo.team2Startup = admin_result.team2Startup; //队伍2首发数组，元素类型是唯一ID
                        gameinfo.roomInfo.team2currentplayers = admin_result.team2currentplayers; //队伍2当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
                    }

                    //获得两队队员的详细信息，并缓存起来
                    this.allTeam1PLayers = await post("/getPlayerInfosOfUids",{uids:gameinfo.team1Player});
                    this.allTeam2Players = await post("/getPlayerInfosOfUids",{uids:gameinfo.team2Player});

                    //设置用户唯一ID和对应数据的map
                    this.ID2DataMap = {};
                    for(var i in this.allTeam1PLayers.players){
                        var uid = this.allTeam1PLayers.players[i].id;
                        this.ID2DataMap[uid] = this.allTeam1PLayers.players[i];
                    }
                    for(var i in this.allTeam2Players.players){
                        var uid = this.allTeam2Players.players[i].id;
                        this.ID2DataMap[uid] = this.allTeam2Players.players[i];
                    }

                    //ID2DataMap存储唯一ID和队员详细信息的对应关系，详细信息的结构如下:{id:0,image:"",nickname:""}

                    this.setState({
                        gameInfo:gameinfo,
                        loading:false
                    })
                    this.setClientPlayers(0);
                    this.setClientPlayers(1);
                    console.log("after:",gameinfo)
                })

            })
        })
    }

    setPermission = (permissions)=>{
        this.socket.emit(serverEvent.setPermission,{permissions:permissions},(data)=>{});
    }

    unsetPermission = (permissions)=>{
        this.socket.emit(serverEvent.unsetPermission,{permissions:permissions},(data)=>{});
    }

    isPlayerInCourt = (uid,team)=>{
        if(team == 0){
            for(var i=0;i<this.state.gameInfo.roomInfo.team1currentplayers.length;i++){
                if(uid == this.state.gameInfo.roomInfo.team1currentplayers[i].uid){
                    return true;
                }
            }
            return false;
        }else{
            for(var i=0;i<this.state.gameInfo.roomInfo.team2currentplayers.length;i++){
                if(uid == this.state.gameInfo.roomInfo.team2currentplayers[i].uid){
                    return true;
                }
            }
            return false;
        }
    }

    setClientPlayers = (team)=>{
        if(team == 0){
            this.state.team1Members = [];
            this.state.members1OffCourt = [];
            for(var i=0;i<this.state.gameInfo.team1Player.length;i++){
                var uid = this.state.gameInfo.team1Player[i]
                if(this.isPlayerInCourt(uid,team)){
                    this.state.team1Members.push(this.ID2DataMap[uid])
                }else{
                    this.state.members1OffCourt.push(this.ID2DataMap[uid])
                }
            }
            this.setState({
                team1Members:this.state.team1Members,
                members1OffCourt:this.state.members1OffCourt
            })
        }else{
            this.state.team2Members = [];
            this.state.members2OffCourt = [];
            for(var i=0;i<this.state.gameInfo.team2Player.length;i++){
                var uid = this.state.gameInfo.team2Player[i]
                if(this.isPlayerInCourt(uid,team)){
                    this.state.team2Members.push(this.ID2DataMap[uid])
                }else{
                    this.state.members2OffCourt.push(this.ID2DataMap[uid])
                }
            }
            this.setState({
                team2Members:this.state.team2Members,
                members2OffCourt:this.state.members2OffCourt
            })
        }
    }

    second2time = (second)=>{
        var m_text = "";
        var s_text = "";
        var m = Math.floor(second/60);
        var s = second%60;
        if(minute = 0){
            m_text = "00"
        }else{
            m_text = m;
        }
        if(s<10){
            s_text = "0"+s;
        }else{
            s_text = s;
        }

        var result = m_text+":"+s_text;
        if(m == 0 && s == 0){
            result = "结束"
        }
        return result;
    }

    //比赛时间倒计时
    countDown = async()=>{
        if(!this.state.isTimerStart){
            //先判断比赛是否已经结束
            if(this.state.gameInfo.roomInfo.currentsectiontime == 0 && this.state.gameInfo.roomInfo.currentsection == 4){
                Toast.info("比赛已经结束")
                return;
            }
            this.setState({isTimerStart:true})
            //判断是否是节间休息，是则重置时间
            if(this.state.gameInfo.roomInfo.currentsectiontime == 0){
                this.state.gameInfo.roomInfo.currentsectiontime = 10*60;
                this.state.gameInfo.roomInfo.currentsection++;
                this.setState({gameInfo:this.state.gameInfo})
                var admin_result = await post("/adminGame",{
                    game_uid:this.state.game_uid,
                    optype:admin_op.update_time,
                    meta:{
                        currentsection:this.state.gameInfo.roomInfo.currentsection,
                        currentsectiontime:this.state.gameInfo.roomInfo.currentsectiontime
                    }
                })
                if(admin_result.error){
                    Toast.info(admin_result.errorinfo,1);
                }

                this.socket.emit(serverEvent.updateTime,{
                    currentsection:this.state.gameInfo.roomInfo.currentsection,
                    currentsectiontime:this.state.gameInfo.roomInfo.currentsectiontime
                })

            }
            //启动计时器
            this.handleTimer = setInterval(()=>{
                this.state.gameInfo.roomInfo.currentsectiontime--;
                var t = this.state.gameInfo.roomInfo.currentsectiontime;
                this.setState({gameInfo:this.state.gameInfo})
                post("/adminGame",{
                    game_uid:this.state.game_uid,
                    optype:admin_op.update_time,
                    meta:{
                        currentsection:this.state.gameInfo.roomInfo.currentsection,
                        currentsectiontime:this.state.gameInfo.roomInfo.currentsectiontime
                    }
                })
                if(t == 0){
                    clearInterval(this.handleTimer)
                    this.setState({isTimerStart:false})
                }

                this.socket.emit(serverEvent.updateTime,{
                    currentsection:this.state.gameInfo.roomInfo.currentsection,
                    currentsectiontime:this.state.gameInfo.roomInfo.currentsectiontime
                })
            },1000)
        }else{
            clearInterval(this.handleTimer)
            clearInterval(this.handle24Timer);
            this.setState({isTimerStart:false})
        }
    }



    ballControlChange = ()=>{
        if(!this.state.isTimerStart){
            Toast.info("计时停止时无法改变球权",1)
            return;
        }
        const BUTTONS = [];
        var team1 = this.props.navigation.state.params.team1;
        var team2 = this.props.navigation.state.params.team2;
        BUTTONS.push(team1.name);
        BUTTONS.push(team2.name);
        BUTTONS.push("取消")
        ActionSheet.showActionSheetWithOptions({
                options: BUTTONS,
                cancelButtonIndex: BUTTONS.length - 1,
                message: '球权',
                maskClosable: true
            },
            (buttonIndex) => {
                if(buttonIndex == 0 || buttonIndex == 1){
                    this.state.gameInfo.roomInfo.currentattacktime = 24;
                    this.state.gameInfo.roomInfo.ballowner = buttonIndex+1;
                    this.setState({gameInfo:this.state.gameInfo})
                    post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_ballcontrol,
                        meta:{
                            ballowner:this.state.gameInfo.roomInfo.ballowner,
                            currentattacktime:this.state.gameInfo.roomInfo.currentattacktime
                        }
                    })
                    this.handle24Timer = setInterval(()=>{
                        var t = this.state.gameInfo.roomInfo.currentattacktime;
                        this.state.gameInfo.roomInfo.currentattacktime--;
                        t--;
                        if(t == 0){
                            this.state.gameInfo.roomInfo.ballowner = 0;
                            clearInterval(this.handle24Timer);
                        }
                        this.setState({gameInfo:this.state.gameInfo});
                        post("/adminGame",{
                            game_uid:this.state.game_uid,
                            optype:admin_op.update_ballcontrol,
                            meta:{
                                ballowner:this.state.gameInfo.roomInfo.ballowner,
                                currentattacktime:this.state.gameInfo.roomInfo.currentattacktime
                            }
                        })
                    },1000)
                }
            })
    }

    reset24 = ()=>{
        this.state.gameInfo.roomInfo.currentattacktime = 24;
        this.state.gameInfo.roomInfo.ballowner = 0;
        this.setState({gameInfo:this.state.gameInfo})
        clearInterval(this.handle24Timer);
        post("/adminGame",{
            game_uid:this.state.game_uid,
            optype:admin_op.update_ballcontrol,
            meta:{
                ballowner:this.state.gameInfo.roomInfo.ballowner,
                currentattacktime:this.state.gameInfo.roomInfo.currentattacktime
            }
        })
    }

    addScore = async(team,score)=>{
        if(team == 0){
            this.state.gameInfo.roomInfo.team1currentscore += score;
            this.setState({gameInfo:this.state.gameInfo})
        }else if(team == 1){
            this.state.gameInfo.roomInfo.team2currentscore += score;
            this.setState({gameInfo:this.state.gameInfo})
        }

        var admin_result = await post("/adminGame",{
            game_uid:this.state.game_uid,
            optype:admin_op.update_score,
            meta:{
                team1currentscore:this.state.gameInfo.roomInfo.team1currentscore,
                team2currentscore:this.state.gameInfo.roomInfo.team2currentscore
            }
        })
        if(admin_result.error){
            Toast.info(admin_result.errorinfo,1);
        }

        this.socket.emit(serverEvent.updateScore,{
            team1currentscore:this.state.gameInfo.roomInfo.team1currentscore,
            team2currentscore:this.state.gameInfo.roomInfo.team2currentscore
        })
    }

    requestTimeout = async(team)=>{
        if(team == 0){
            if(this.state.gameInfo.roomInfo.team1timeout == 0){
                Toast.info("暂停已经用完")
                return;
            }
            this.state.gameInfo.roomInfo.team1timeout -= 1;
            this.setState({gameInfo:this.state.gameInfo})
        }else if(team == 1){
            if(this.state.gameInfo.roomInfo.team2timeout == 0){
                Toast.info("暂停已经用完")
                return;
            }
            this.state.gameInfo.roomInfo.team2timeout -= 1;
            this.setState({gameInfo:this.state.gameInfo})
        }

        var admin_result = await post("/adminGame",{
            game_uid:this.state.game_uid,
            optype:admin_op.update_timeout,
            meta:{
                team1timeout:this.state.gameInfo.roomInfo.team1timeout,
                team2timeout:this.state.gameInfo.roomInfo.team2timeout
            }
        })
        if(admin_result.error){
            Toast.info(admin_result.errorinfo,1);
        }
    }

    addShoot = async(msg)=>{
        console.log("onAddShoot:",msg);
        if(!this.state.gameInfo.roomInfo[msg.player_uid]){
            this.state.gameInfo.roomInfo[msg.player_uid] = {};
        }
        if(!this.state.gameInfo.roomInfo[msg.player_uid]["shoot"]){
            this.state.gameInfo.roomInfo[msg.player_uid]["shoot"] = [];
        }
        var section = this.state.gameInfo.roomInfo.currentsection;
        var time = this.state.gameInfo.roomInfo.currentsectiontime;
        var time24 = this.state.gameInfo.roomInfo.currentattacktime;
        msg.shootpoint.section = section;
        msg.shootpoint.time = time;
        msg.shootpoint.time24 = time24;
        this.state.gameInfo.roomInfo[msg.player_uid]["shoot"].push(msg.shootpoint);
        this.setState({gameInfo:this.state.gameInfo})
        var admin_result = await post("/adminGame",{
            game_uid:this.state.game_uid,
            optype:admin_op.update_shoot,
            meta:{
                uid:msg.player_uid,
                shoot:this.state.gameInfo.roomInfo[msg.player_uid]["shoot"]
            }
        })
        if(admin_result.error){
            Toast.info(admin_result.errorinfo,1);
        }
    }

    addFreethrow = async(msg)=>{
        if(!this.state.gameInfo.roomInfo[msg.player_uid]){
            this.state.gameInfo.roomInfo[msg.player_uid] = {};
        }
        if(!this.state.gameInfo.roomInfo[msg.player_uid]["freethrow"]){
            this.state.gameInfo.roomInfo[msg.player_uid]["freethrow"] = [];
        }
        var section = this.state.gameInfo.roomInfo.currentsection;
        var time = this.state.gameInfo.roomInfo.currentsectiontime;
        var time24 = this.state.gameInfo.roomInfo.currentattacktime;
        msg.freethrow.section = section;
        msg.freethrow.time = time;
        msg.freethrow.time24 = time24;
        this.state.gameInfo.roomInfo[msg.player_uid]["freethrow"].push(msg.freethrow);
        this.setState({gameInfo:this.state.gameInfo})
        var admin_result = await post("/adminGame",{
            game_uid:this.state.game_uid,
            optype:admin_op.update_freethrow,
            meta:{
                uid:msg.player_uid,
                freethrow:this.state.gameInfo.roomInfo[msg.player_uid]["freethrow"]
            }
        })
        if(admin_result.error){
            Toast.info(admin_result.errorinfo,1);
        }
    }

    playerChanged =async(msg)=>{
        if(msg.team==0){
            var index = -1;
            for(var i=0;i<this.state.gameInfo.roomInfo.team1currentplayers.length;i++){
                if(this.state.gameInfo.roomInfo.team1currentplayers[i].uid == msg.off_uid){
                    index = i;
                    break;
                }
            }
            this.state.gameInfo.roomInfo.team1currentplayers.splice(index,1,{uid:msg.on_uid})
            this.setClientPlayers(0);
            var admin_result = await post("/adminGame",{
                game_uid:this.state.game_uid,
                optype:admin_op.substitution,
                meta:{
                    player_up_uid:msg.on_uid,
                    player_down_uid:msg.off_uid,
                    team_index:0
                }
            })
            if(admin_result.error){
                Toast.info(admin_result.errorinfo,1);
            }
        }else{
            var index = -1;
            for(var i=0;i<this.state.gameInfo.roomInfo.team2currentplayers.length;i++){
                if(this.state.gameInfo.roomInfo.team2currentplayers[i].uid == msg.off_uid){
                    index = i;
                    break;
                }
            }
            this.state.gameInfo.roomInfo.team2currentplayers.splice(index,1,{uid:msg.on_uid})
            this.setClientPlayers(1);
            var admin_result = await post("/adminGame",{
                game_uid:this.state.game_uid,
                optype:admin_op.substitution,
                meta:{
                    player_up_uid:msg.on_uid,
                    player_down_uid:msg.off_uid,
                    team_index:1
                }
            })
            if(admin_result.error){
                Toast.info(admin_result.errorinfo,1);
            }
        }
    }

    gotoTeamsubstitution = (index)=>{
        if(index == 0){
            if(this.state.members1OffCourt.length == 0){
                Toast.info("无人可换",1)
                return;
            }
            this.props.navigation.navigate("substitution",{
                team:0,
                teamMembers:this.state.team1Members,
                membersOffCourt:this.state.members1OffCourt
            })
        }else{
            if(this.state.members2OffCourt.length == 0){
                Toast.info("无人可换",1)
                return;
            }
            this.props.navigation.navigate("substitution",{
                team:1,
                teamMembers:this.state.team2Members,
                membersOffCourt:this.state.members2OffCourt
            })
        }

    }

    gotoShootPoint = (item)=>{
        var game_uid = this.props.navigation.state.params.game_uid;
        var player = item;
        var shoot_array = this.state.gameInfo.roomInfo[item.id]?this.state.gameInfo.roomInfo[item.id]['shoot']?this.state.gameInfo.roomInfo[item.id]['shoot']:[]:[];
        var freethrow_array = this.state.gameInfo.roomInfo[item.id]?this.state.gameInfo.roomInfo[item.id]['freethrow']?this.state.gameInfo.roomInfo[item.id]['freethrow']:[]:[];
        this.props.navigation.navigate("ShootPoint",{game_uid,player,shoot_array,freethrow_array})
    }

    componentDidMount(){
        this.adminGame();
        emitter.on("onAddShoot",this.addShoot)
        emitter.on("playerChanged",this.playerChanged)
        emitter.on("addFreethrow",this.addFreethrow);
    }

    componentWillUnmount(){
        this.socket.disconnect();
        clearInterval(this.handleTimer)
        clearInterval(this.handle24Timer);
        emitter.removeListener("onAddShoot",this.addShoot)
        emitter.removeListener("playerChanged",this.playerChanged)
        emitter.removeListener("addFreethrow",this.addFreethrow)
    }

    dataStatistics = (id,nickname,team) => {
        const BUTTONS = ['1分', '2分', '3分','篮板','助攻','抢断','失误','犯规',"盖帽"];
        ActionSheet.showActionSheetWithOptions({
                options: BUTTONS,
                cancelButtonIndex: BUTTONS.length - 1,
                destructiveButtonIndex: BUTTONS.length - 2,
                message: nickname+'的技术统计',
                maskClosable: true
            },
            async(buttonIndex) => {
                //Toast.info(BUTTONS[buttonIndex],1)
                var section = this.state.gameInfo.roomInfo.currentsection;
                var time = this.state.gameInfo.roomInfo.currentsectiontime;
                var time24 = this.state.gameInfo.roomInfo.currentattacktime;
                if(buttonIndex == 0){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["point"]){
                        this.state.gameInfo.roomInfo[id]["point"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["point"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_point,
                        meta:{
                            uid:id,
                            point:this.state.gameInfo.roomInfo[id]["point"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 1){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["point"]){
                        this.state.gameInfo.roomInfo[id]["point"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["point"].push({number:2,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_point,
                        meta:{
                            uid:id,
                            point:this.state.gameInfo.roomInfo[id]["point"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 2){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["point"]){
                        this.state.gameInfo.roomInfo[id]["point"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["point"].push({number:3,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_point,
                        meta:{
                            uid:id,
                            point:this.state.gameInfo.roomInfo[id]["point"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 3){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["rebound"]){
                        this.state.gameInfo.roomInfo[id]["rebound"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["rebound"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_rebound,
                        meta:{
                            uid:id,
                            rebound:this.state.gameInfo.roomInfo[id]["rebound"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 4){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["assists"]){
                        this.state.gameInfo.roomInfo[id]["assists"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["assists"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_assists,
                        meta:{
                            uid:id,
                            assists:this.state.gameInfo.roomInfo[id]["assists"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 8){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["block"]){
                        this.state.gameInfo.roomInfo[id]["block"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["block"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_block,
                        meta:{
                            uid:id,
                            block:this.state.gameInfo.roomInfo[id]["block"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 5){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["steals"]){
                        this.state.gameInfo.roomInfo[id]["steals"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["steals"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_steals,
                        meta:{
                            uid:id,
                            steals:this.state.gameInfo.roomInfo[id]["steals"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 6){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["fault"]){
                        this.state.gameInfo.roomInfo[id]["fault"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["fault"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_fault,
                        meta:{
                            uid:id,
                            fault:this.state.gameInfo.roomInfo[id]["fault"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }else if(buttonIndex == 7){
                    if(!this.state.gameInfo.roomInfo[id]){
                        this.state.gameInfo.roomInfo[id] = {};
                    }
                    if(!this.state.gameInfo.roomInfo[id]["foul"]){
                        this.state.gameInfo.roomInfo[id]["foul"] = [];
                    }
                    this.state.gameInfo.roomInfo[id]["foul"].push({number:1,section:section,time:time,time24:time24})
                    this.setState({gameInfo:this.state.gameInfo})
                    var admin_result = await post("/adminGame",{
                        game_uid:this.state.game_uid,
                        optype:admin_op.update_Foul,
                        meta:{
                            uid:id,
                            foul:this.state.gameInfo.roomInfo[id]["foul"]
                        }
                    })
                    if(admin_result.error){
                        Toast.info(admin_result.errorinfo,1);
                    }
                }
            });
    }

    obj2number = (playerdata,type)=>{
        if(!playerdata){
            return 0;
        }
        if(!playerdata[type]){
            return 0;
        }

        var total = 0;
        for(var i=0;i<playerdata[type].length;i++){
            total += playerdata[type][i].number;
        }
        return total;
    }

    onModalShow = ()=>{
        this.setState({modelvisible:true})
    }

    onModalClose = ()=>{
        this.setState({modelvisible:false})
    }

    render(){
        var team1 = this.props.navigation.state.params.team1;
        var team2 = this.props.navigation.state.params.team2;
        //设置比赛时间组件需要的属性
        var MatchTimer_Props = null;
        var CurrentMatchTeam1_Props = null;
        var CurrentMatchTeam2_Props = null;
        if(!this.state.loading){
            MatchTimer_Props  = {
                isTimerStart:this.state.isTimerStart,
                currentsection:this.state.gameInfo.roomInfo.currentsection,
                currentsectiontime:this.state.gameInfo.roomInfo.currentsectiontime,
                currentattacktime:this.state.gameInfo.roomInfo.currentattacktime,
                countDown:this.countDown,
                ballControlChange:this.ballControlChange,
                reset24:this.reset24,
                gotoTeamShootPoint:this.gotoTeamShootPoint
            }

            CurrentMatchTeam1_Props = {
                teamindex:0,
                teaminfo:team1,
                teamcurrentscore:this.state.gameInfo.roomInfo.team1currentscore,
                teamMembers:this.state.team1Members,
                roomInfo:this.state.gameInfo.roomInfo,
                teamtimeout:this.state.gameInfo.roomInfo.team1timeout,
                addScore:this.addScore,
                dataStatistics:this.dataStatistics,
                gotoShootPoint:this.gotoShootPoint,
                requestTimeout:this.requestTimeout,
                gotoTeamsubstitution:this.gotoTeamsubstitution,
                isBonus:this.isBonus
            }

            CurrentMatchTeam2_Props = {
                teamindex:1,
                teaminfo:team2,
                teamcurrentscore:this.state.gameInfo.roomInfo.team2currentscore,
                teamMembers:this.state.team2Members,
                roomInfo:this.state.gameInfo.roomInfo,
                teamtimeout:this.state.gameInfo.roomInfo.team2timeout,
                addScore:this.addScore,
                dataStatistics:this.dataStatistics,
                gotoShootPoint:this.gotoShootPoint,
                requestTimeout:this.requestTimeout,
                gotoTeamsubstitution:this.gotoTeamsubstitution,
                isBonus:this.isBonus
            }
        }

        return (
            <View style={{flex:1}}>
                <ToolBar title="技术统计" navigation={this.props.navigation} />
                {this.state.loading?<ActivityIndicator/>:<ScrollView style={styles.container}>
                    <WingBlank>
                        <WhiteSpace/>
                        <CurrentMatchTeam {...CurrentMatchTeam1_Props} />
                        <WhiteSpace size="xs"/>
                        <View style={styles.comment}>
                            <WhiteSpace/>
                            <WingBlank>
                                <Text>注：得分，篮板，助攻，盖帽，抢断，失误</Text>
                            </WingBlank>
                            <WhiteSpace/>
                        </View>
                        <WhiteSpace size="xs"/>
                        <MatchTimer {...MatchTimer_Props} />
                        <WhiteSpace size="xs"/>
                        <CurrentMatchTeam {...CurrentMatchTeam2_Props} />
                        <WhiteSpace/>
                    </WingBlank>
                </ScrollView>}
            </View>
        )
    }
}