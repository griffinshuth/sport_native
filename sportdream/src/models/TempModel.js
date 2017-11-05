
export default {
    namespace:'temp',
    state:{
        loadfromstore:false,
        loginLoading:false,
        loginError:0
    },
    reducers:{
        storeloaded(state,{payload}){
            return {...state,loadfromstore:true}
        },
        loginLoading(state,{payload}){
            return {...state,loginLoading:payload.loginLoading}
        },
        loginError(state,{payload}){
            return {...state,loginError:payload.loginError}
        }
    },

}