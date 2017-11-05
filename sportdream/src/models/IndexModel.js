import {NavigationActions} from 'react-navigation'
const createAction = type => payload => ({type,payload})
import {get,post} from '../fetch.js'

export default {
    namespace:'appNS',
    state:{
        token:"",
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
                    /*yield put(
                        NavigationActions.reset({
                            index: 0,
                            actions: [NavigationActions.navigate({ routeName: 'Profile' })],
                        })
                    );*/
                }else{
                    yield put(createAction('temp/loginError')({loginError:result.error}))
                }
            }catch(e){
                console.error(e);
            }
        }
    }
}