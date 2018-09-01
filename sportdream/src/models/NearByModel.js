import {get,post} from '../fetch.js'

export default {
    namespace:'NearBy',
    state:{
        loading:false,
        users:[]
    },
    reducers:{
        initUsers(state,{payload}){
            var {users} = payload;
            return {...state,users:users}
        }
    },
    effects:{
        *getNearbyUsers({payload},{put,call}){
            var result = yield call(()=>post("/getNearbyUsers",{}));
            yield put({type:"initUsers",payload:{users:result.users}})
        }
    }
}