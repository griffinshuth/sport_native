import React from 'react'
import {
    View,
    Text
} from 'react-native'
import io from 'socket.io-client'
import ToolBar from '../../Components/ToolBar'

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            message:""
        }
    }

    componentDidMount(){
        var socket = io("http://192.168.0.105",{
            //transports: ['websocket'],
        });
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="实时聊天" navigation={this.props.navigation}/>
                <Text>{this.state.message}</Text>
            </View>
        )
    }
}

