const createAction = type => payload => ({type,payload})
import {get,post} from '../fetch.js'

export default {
    namespace:'user',
    state:{
        uid:-1,
        phonenumber:"",
        password:"",
        nickname:"",
        sex:"",
        headerimage:null,
        birthday:null,
        weight:null,
        height:null,
        createtime:-1
    },
    reducers:{
        initUserInfo(state,{payload}){
            return {...state,...payload}
        },
        updateHeaderImage(state,{payload}){
            return {...state,...payload}
        }
    },
    effects:{
        *getUserInfo({payload},{put,call}){
            try{
                const result = yield call(()=>get('/getUserInfo',payload))
                if(!result.error){
                    yield put({type:'temp/ServerConnected',payload:{tokenExpired:false}})
                    yield put(createAction('initUserInfo')(result.data))
                }else{
                    yield put({type:'temp/ServerConnected',payload:{tokenExpired:true}})
                    yield put(createAction('appNS/loginout')())
                }
            }catch(e){
                console.log(e);
                yield put({type:'temp/clientOffline',payload:{}})
            }
        }
    }
}