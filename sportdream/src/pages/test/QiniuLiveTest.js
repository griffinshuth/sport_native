import React from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    Platform,
    requireNativeComponent,
    NativeModules,
    DeviceEventEmitter,
    NativeAppEventEmitter
} from 'react-native'
import {
    WhiteSpace,
    Toast,
    Button
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {get,post} from '../../fetch'

var QiniuPushView = requireNativeComponent('QiniuPushView', null);
var QiniuPlayView = requireNativeComponent('QiniuPlayView', null);

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            pushUrl:"",
            loading:true,
        }
    }

    getLiveUrl = async()=>{
        var push = await post("/getPublishURL",{streamname:"test2"})
        this.setState({pushUrl:push.url,loading:false})
    }

    componentWillMount(){
        this.getLiveUrl();
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="七牛直播" navigation={this.props.navigation}/>
                <Text>{this.state.pushUrl}</Text>

                {this.state.loading?null:<QiniuPushView
                        rtmpURL={this.state.pushUrl}
                        style={{
                            height:400,
                            width:300,
                        }}
                        zoom={1}
                        focus={true}
                        profile={{
                            video:{
                                fps:30,
                                bps:1000 * 1024,
                                maxFrameInterval:48
                            },
                            audio:{
                                rate:44100,
                                bitrate:96 * 1024
                            }
                        }}
                        started={true}

                    />}
            </View>
        )
    }
}