import {NavigationActions} from 'react-navigation'
const createAction = type => payload => ({type,payload})
import {get,post} from '../fetch.js'
var genUuid = require('uuid/v4')

export default {
    namespace:'appNS',
    state:{
        token:"",
        clientID:"",
    },
    reducers:{
        loginSuccessed(state,{payload}){
            return {
                ...state,
                token:payload.token,
            }
        },
        loginout(state,{payload}){
            return {
                ...state,
                token:"",
            }
        },

        genClientID(state,{payload}){
            if(state.clientID){
                return {
                    ...state
                }
            }else{
                var uuid = genUuid();
                return {
                    ...state,
                    clientID:uuid
                }
            }
        }

    },
    effects:{
        *login({payload},{put,call}){
            try{
                yield put(createAction('temp/loginLoading')({loginLoading:true}))
                yield put(createAction('temp/loginError')({loginError:0}))
                const result = yield call(()=>get('/login',payload))
                yield put(createAction('temp/loginLoading')({loginLoading:false}))
                if(!result.error){
                    yield put(createAction('loginSuccessed')(result));
                    yield put({type:'temp/ServerConnected',payload:{tokenExpired:false}})
                }else{
                    yield put(createAction('temp/loginError')({loginError:result.error}))
                }
            }catch(e){
                console.error(e);
            }
        }
    }
}