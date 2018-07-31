import React from 'react'
import dva,{connect} from 'dva/mobile'
import {persistStore,autoRehydrate} from 'redux-persist'
import {Provider} from 'react-redux'
import {create} from 'dva-core'
import {
    AppRegistry,
    StyleSheet,
    Text,
    View,
    Button,
    Platform,
    TouchableHighlight,
    AsyncStorage
} from 'react-native'


import {StackNavigator} from 'react-navigation'
import IndexModel from './models/IndexModel'
import routerModel from './models/routerModel'
import CountModel from './models/CountModel'
import TempModel from './models/TempModel'
import UserModel from './models/UserModel'
import CurrentAdminMatchModel from './models/CurrentAdminMatchModel'
import Router from './router'

const app = create({
    extraEnhancers:[autoRehydrate()],
    onError(e){
        console.log('onError',e);
    }
});
app.model(IndexModel);
app.model(routerModel);
app.model(CountModel);
app.model(TempModel);
app.model(UserModel);
app.model(CurrentAdminMatchModel);

//app.router(()=><Router/>)
app.start();

const store = app._store
const AppWithPersist =  () =>
    <Provider store={store}>
        <Router/>
    </Provider>

persistStore(store, { storage: AsyncStorage ,blacklist:['temp']},function(){
    console.log("persistStore finished:"+JSON.stringify(arguments))
    store.dispatch({type:'temp/storeloaded'})
    store.dispatch({type:'appNS/genClientID'})
})

AppRegistry.registerComponent('sportdream',()=>AppWithPersist)


