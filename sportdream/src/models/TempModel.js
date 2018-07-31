
export default {
    namespace:'temp',
    state:{
        loadfromstore:false,
        isServerConnected:false,
        isOffline:false,
        tokenExpired:false,
        loginLoading:false,
        loginError:0
    },
    reducers:{
        storeloaded(state,{payload}){
            return {...state,loadfromstore:true}
        },
        ServerConnected(state,{payload}){
           return {...state,isServerConnected:true,tokenExpired:payload.tokenExpired,isOffline:false}
        },
        clientOffline(state,{payload}){
            return {...state,isOffline:true}
        },
        loginLoading(state,{payload}){
            return {...state,loginLoading:payload.loginLoading}
        },
        loginError(state,{payload}){
            return {...state,loginError:payload.loginError}
        }
    },

}