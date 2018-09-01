import {get,post} from '../fetch.js'

export default {
    namespace:'TimeLine',
    state:{
        loading:false,
        timelines:[]
    },
    reducers:{
        setLoadState(state,{payload}){
            var {loading} = payload;
            return {...state,loading:loading}
        },
        loadAllTimeLine(state,{payload}){
            const {timelines} = payload;
            return {...state,timelines:timelines}
        }
    },
    effects:{
        *getAllTimeLine({payload},{put,call}){
            yield put({type:'setLoadState',payload:{loading:true}});
            var result = yield call(()=>post("/getAllTimeLines",{}));
            yield put({type:'loadAllTimeLine',payload:{timelines:result.timelines}})
            yield put({type:'setLoadState',payload:{loading:false}});
        },
        *sendTimeLineComment({payload},{put,call}){
            var {token,timelineuid,iszan,text} = payload;
            yield call(()=>post("/commentTimeLine",{token,timelineuid,iszan,text}));
            var result = yield call(()=>post("/getAllTimeLines",{}));
            yield put({type:'loadAllTimeLine',payload:{timelines:result.timelines}})
        }
    }
}