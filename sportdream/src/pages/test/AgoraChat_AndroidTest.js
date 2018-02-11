import React from 'react'
import {
    StyleSheet,
    View,
    Text,
    requireNativeComponent,
    DeviceEventEmitter
} from 'react-native'
import {
    Button,
    WhiteSpace,
    Toast
} from 'antd-mobile'
var AgorachatView = requireNativeComponent("AgorachatView",null);
import ToolBar from '../../Components/ToolBar'

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            status:0,
            channel:"test",
            players : []
        }

    }

    componentDidMount(){
        this.onUserOffline = DeviceEventEmitter.addListener('onUserOffline', (data) => {
            // handle event.
            var index = this.state.players.indexOf(data.uid);
            if(index>=0){
                this.state.players.splice(index,1);
                this.setState({players:this.state.players})
            }
        });
        this.onUserJoined = DeviceEventEmitter.addListener('onUserJoined', (data)=> {
            // handle event.
            this.state.players.push(data.uid);
            this.setState({players:this.state.players})
        });
        this.onLeaveChannel = DeviceEventEmitter.addListener('onLeaveChannel', (data)=> {
            // handle event.
            this.props.navigation.goBack();
        });
        this.setState({status:1})
    }

    componentWillUnmount(){
        this.onUserOffline.remove();
        this.onUserJoined.remove();
        this.onLeaveChannel.remove();
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="视频聊天" navigation={this.props.navigation}/>
               <Button onClick={()=>{this.setState({status:2})}}>离开房间</Button>
                <AgorachatView uid={0} status={this.state.status} channel={this.state.channel} style={{width:240,height:320}}/>
                {
                    this.state.players.map((item)=>{
                        return <View key={item}>
                            <WhiteSpace/>
                            <AgorachatView uid={item} status={0} channel={this.state.channel} style={{width:120,height:160}}/>
                        </View>
                    })
                }
            </View>);
    }
}