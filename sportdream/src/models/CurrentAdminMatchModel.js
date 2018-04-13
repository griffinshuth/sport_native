const createAction = type => payload => ({type,payload})
import {get,post} from '../fetch.js'
import {clientEvent,serverEvent,permissionType,admin_op} from '../utils/socketEvent'
import { Platform } from 'react-native';

export default {
    namespace:"CurrentAdminMatchModel",
    state:{
        loading:true,
        game_uid:null,
        team1Members:[],  //场上球员实体列表,结构如下:{id:0,image:"",nickname:""}
        team2Members:[],  //场上球员实体列表,结构如下:{id:0,image:"",nickname:""}
        members1OffCourt:[], //场下球员实体列表,结构如下:{id:0,image:"",nickname:""}
        members2OffCourt:[], //场下球员实体列表,结构如下:{id:0,image:"",nickname:""}
        isTimerStart:false,

        //team1IndexPlayer:[], //该字段存储的是队伍1的大名单，类型是数组，里面的元素是唯一ID
        //team1IndexStartup:[],     //队伍1首发数组，元素类型是唯一ID
        //team1currentplayers:[],  //队伍1当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
        //team2IndexPlayer:[], //该字段存储的是队伍2的大名单，类型是数组，里面的元素是唯一ID
        //team2IndexStartup:[],     //队伍2首发数组，元素类型是唯一ID
        //team2currentplayers:[],  //队伍2当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
        //ID2DataMap:{},  //存储唯一ID和队员详细信息的对应关系，详细信息的结构如下:{id:0,image:"",nickname:""}

        ballowner:0,    //拥有球权的一方，0代表双方都没有控制住球，1代表队伍1控制住球，2代表队伍2控制住球
        currentattacktime:24, //进攻24秒
        currentsection:1,     //当前第几节
        currentsectiontime:0, //当前节持续了多少秒
        team1currentscore:0, //队伍1的得分
        team2currentscore:0, //队伍2的得分
        team1timeout:7,      //队伍1的暂停数
        team2timeout:7,      //队伍2的暂停数

        //队伍1技术统计
        //主键是队员唯一ID，值是队员数据，格式如下：{point:[],rebound:[],assists:[],block:{},steals:[],fault:[],foul:[],freethrow:[],shoot:[]}
        //point数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //rebound数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //assists数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //block数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //steals数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //fault数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //foul数组元素的数据结构:{number:1,section:section,time:time,time24:time24}
        //freethrow数组元素的数据结构:{type:type,shoot:2,score:2,section:section,time:time,time24:time24}
        //shoot数组元素的数据结构:x:0,y:0,point:2,score:true,section:section,time:time,time24:time24}
        team1dataStatistics:{},
        //队伍2技术统计
        team2dataStatistics:{},
        //
        need01:(Platform.OS === 'ios') ? true : false,

    },
    reducers:{
        init(state,{payload}){
            console.log("dispatch reducer init!");
            return {...state,loading:false,isTimerStart:false,...payload};
        },
        destroy(state){
            return {...state,loading:true}
        },
        timestart(state,{payload}){
            const {isTimerStart} = payload;
            let {currentsectiontime,currentsection,currentattacktime} = state;
            if(currentattacktime == 0){
                //24秒为零，需要用户重置24秒
                return state;
            }
            if(currentsection == 4 && currentsectiontime == 0){
                //比赛结束
                return state;
            }
            if(currentsectiontime == 0){
                currentsectiontime = 12*60;
                currentsection++;
                return {...state,isTimerStart,currentsection,currentsectiontime}
            }
            return {...state,...payload}
        },
        countdown(state,{payload}){
            var t = state.currentsectiontime - payload.time;
            if(t<60){
                t = t.toFixed(1);
            }
            if(t>0){
                return {...state,currentsectiontime:t};
            }else{
                return {...state,currentsectiontime:t,isTimerStart:false}
            }
        },
        ballownerchange(state,{payload}){
            return {...state,...payload}
        },
        reset24(state,{payload}){
            return {...state,...payload}
        },
        countdown24(state,{payload}){
            var t = state.currentattacktime - payload.time;
            if(t<5){
                t = t.toFixed(1);
            }
            if(t>0){
                return {...state,currentattacktime:t};
            }else{
                return {...state,currentattacktime:t,isTimerStart:false}
            }

        },
        setCountDownStyle(state,{payload}){
            const {need01} = payload;
            return {...state,need01}
        },
        addScore(state,{payload}){
            const {teamIndex,score} = payload;
            if(teamIndex == 0){
                var t = state.team1currentscore+score;
                return {...state,team1currentscore:t}
            }else{
                var t = state.team2currentscore+score;
                return {...state,team2currentscore:t}
            }
        },
        requestTimeout(state,{payload}){
            const {teamIndex} = payload;
            if(teamIndex == 0){
                if(state.team1timeout == 0){
                    return state;
                }else{
                    var t = state.team1timeout-1;
                    return {...state,team1timeout:t}
                }
            }else{
                if(state.team2timeout == 0){
                    return state;
                }else{
                    var t = state.team2timeout-1;
                    return {...state,team2timeout:t}
                }
            }
        },
        addDataStatistics(state,{payload}){
            const {id,type,value,teamindex} = payload
            if(type == "shoot" || type== "freethrow") {
                var obj = {
                    ...value,
                    section: state.currentsection,
                    time: state.currentsectiontime,
                    time24: state.currentattacktime
                }
            }else{
                var obj = {number:value,section:state.currentsection,time:state.currentsectiontime,time24:state.currentattacktime}
            }

            if(teamindex == 0){
                if(!state.team1dataStatistics[id]){
                    let singleStat = {};
                    singleStat[type] = [obj];
                    let singleperson = {};
                    singleperson[id] = singleStat;
                    return {...state,team1dataStatistics:{...state.team1dataStatistics,...singleperson}};
                }else if(!state.team1dataStatistics[id][type]){
                    let singleStat = {};
                    singleStat[type] = [obj];
                    let team1dataStatistics_id_detail = {...state.team1dataStatistics[id],...singleStat}
                    let singleperon = {};
                    singleperon[id] = team1dataStatistics_id_detail;
                    return {...state,team1dataStatistics:{...state.team1dataStatistics,...singleperon}}
                }else{
                    let singletype_array = [...state.team1dataStatistics[id][type],obj];
                    let ts_id_type = {};
                    ts_id_type[type] = singletype_array;
                    let ts_id = {};
                    ts_id[id] = {...state.team1dataStatistics[id],...ts_id_type};
                    return {...state,team1dataStatistics:{...state.team1dataStatistics,...ts_id}}
                }
            }else{
                if(!state.team2dataStatistics[id]){
                    let singleStat = {};
                    singleStat[type] = [obj];
                    let singleperson = {};
                    singleperson[id] = singleStat;
                    return {...state,team2dataStatistics:{...state.team2dataStatistics,...singleperson}};
                }else if(!state.team2dataStatistics[id][type]){
                    let singleStat = {};
                    singleStat[type] = [obj];
                    let team2dataStatistics_id_detail = {...state.team2dataStatistics[id],...singleStat}
                    let singleperon = {};
                    singleperon[id] = team2dataStatistics_id_detail;
                    return {...state,team2dataStatistics:{...state.team2dataStatistics,...singleperon}}
                }else{
                    let singletype_array = [...state.team2dataStatistics[id][type],obj];
                    let ts_id_type = {};
                    ts_id_type[type] = singletype_array;
                    let ts_id = {};
                    ts_id[id] = {...state.team2dataStatistics[id],...ts_id_type};
                    return {...state,team2dataStatistics:{...state.team2dataStatistics,...ts_id}}
                }
            }
        },
        playerChanged(state,{payload}){
            const {teamIndex,offIndex,onIndex} = payload;
            if(teamIndex == 0){
                var new_on_array = state.team1Members.filter((item,index)=>{
                    return index!=offIndex;
                })
                var on_delete = state.team1Members[offIndex];
                var new_off_array = state.members1OffCourt.filter((item,index)=>{
                    return index != onIndex;
                })
                var off_delete = state.members1OffCourt[onIndex]
                return {
                    ...state,
                    team1Members:[...new_on_array,off_delete],
                    members1OffCourt:[...new_off_array,on_delete]
                }
            }else{
                var new_on_array = state.team2Members.filter((item,index)=>{
                    return index!=offIndex;
                })
                var on_delete = state.team2Members[offIndex];
                var new_off_array = state.members2OffCourt.filter((item,index)=>{
                    return index != onIndex;
                })
                var off_delete = state.members2OffCourt[onIndex]
                return {
                    ...state,
                    team2Members:[...new_on_array,off_delete],
                    members2OffCourt:[...new_off_array,on_delete]
                }
            }
        }
    },
    effects:{
        *loadFromServer({payload},{put,call}){
            const {game_uid,team1PlayerUids,team2PlayerUids} = payload;
            var gameinfo = yield call(()=>post("/getGameInfo",{game_uid:game_uid}));
            if(gameinfo.team1Player.length == 0){
                var admin_result = yield call(()=>post("/adminGame",{
                    game_uid:game_uid,
                    optype:admin_op.insquad,
                    meta:{players:team1PlayerUids,teamindex:0}
                }));
                gameinfo.team1Player = admin_result.team1Player //该字段存储的是队伍1的大名单，类型是数组，里面的元素是唯一ID
                //设置首发
                var startLineUp = [];
                for(var i=0;i<5;i++){
                    startLineUp.push(gameinfo.team1Player[i])
                }
                var admin_result = yield call(()=>post("/adminGame",{
                    game_uid:game_uid,
                    optype:admin_op.startup,
                    meta:{players:startLineUp,teamindex:0}
                }));
                gameinfo.team1Startup = admin_result.team1Startup; //队伍1首发数组，元素类型是唯一ID
                gameinfo.roomInfo.team1currentplayers = admin_result.team1currentplayers; //队伍1当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
            }
            if(gameinfo.team2Player.length == 0){
                var admin_result = yield call(()=>post("/adminGame",{
                    game_uid:game_uid,
                    optype:admin_op.insquad,
                    meta:{players:team2PlayerUids,teamindex:1}
                }));
                gameinfo.team2Player = admin_result.team2Player  //该字段存储的是队伍2的大名单，类型是数组，里面的元素是唯一ID
                //设置首发
                var startLineUp = [];
                for(var i=0;i<5;i++){
                    startLineUp.push(gameinfo.team2Player[i])
                }
                var admin_result = yield call(()=>post("/adminGame",{
                    game_uid:game_uid,
                    optype:admin_op.startup,
                    meta:{players:startLineUp,teamindex:1}
                }));
                gameinfo.team2Startup = admin_result.team2Startup; //队伍2首发数组，元素类型是唯一ID
                gameinfo.roomInfo.team2currentplayers = admin_result.team2currentplayers; //队伍2当前在场上的球员数组，元素类型是对象，结构如下:{uid:0,playingtime:0}
            }
            //获得两队队员的详细信息，并缓存起来
            var allTeam1PLayers = yield call(()=>post("/getPlayerInfosOfUids",{uids:gameinfo.team1Player}));
            var allTeam2Players = yield call(()=>post("/getPlayerInfosOfUids",{uids:gameinfo.team2Player}));

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
            yield put({type:'init',payload:final_state})
        }
    }
}









































