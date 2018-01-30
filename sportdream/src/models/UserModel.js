const createAction = type => payload => ({type,payload})
import {get,post} from '../fetch.js'

export default {
    namespace:'user',
    state:{

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
            const result = yield call(()=>get('/getUserInfo',payload))
            if(!result.error){
                yield put(createAction('initUserInfo')(result.data))
            }else{
                yield put(createAction('appNS/loginout')())
            }

        }
    }
}