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

class HomeScreen extends React.Component{
    static navigationOptions = {
        title:'Welcome'
    };
    render(){
        const {navigate} = this.props.navigation;
        return (
            <View>
                <Text>Hello,sport!</Text>
                <Button onPress={()=>navigate('Chat',{user:'mangguo'})} title="Chat with mangguo"></Button>
            </View>
        )
    }
}

class ChatScreen extends React.Component{
    static navigationOptions = ({navigation}) => ({
        title:`Chat with ${navigation.state.params.user}`
    })

    render(){
        const {params} = this.props.navigation.state;
        return (
            <View>
                <Text>Chat with {params.user}</Text>
            </View>
        )
    }
}

const SportDream = StackNavigator({
    Home:{screen:HomeScreen},
    Chat:{
        screen:ChatScreen,
        path:'chat/:user'
    }
})

const prefix = Platform.OS == 'android'?'mychat://mychat/':'mychat://';

const MainApp = ()=> <SportDream uriPrefix={prefix} />

AppRegistry.registerComponent('sportdream',()=>AppWithPersist)


