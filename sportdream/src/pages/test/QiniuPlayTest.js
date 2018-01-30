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
    NativeAppEventEmitter,
    Dimensions
} from 'react-native'
import {
    WhiteSpace,
    Toast,
    Button
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {get,post} from '../../fetch'

const QiniuPlayView = requireNativeComponent('QiniuPlayView', null);

var {height, width} = Dimensions.get('window');

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            playUrl:"",
            loading:true,
        }
    }
    getLiveUrl = async()=>{
        var play = await post("/getRTMPPlayURL",{streamname:"test2"})
        this.setState({playUrl:play.url,loading:false})
    }

    componentWillMount(){
        this.getLiveUrl();
    }

    render(){
        return (
            <View>
                <ToolBar title="七牛直播" navigation={this.props.navigation}/>
                <Text>{this.state.playUrl}</Text>
                {this.state.loading?null:<QiniuPlayView
                    source={{
                        uri:this.state.playUrl,
                        timeout: 10 * 1000,
                        live:true,
                        hardCodec:false,
                    }}
                    started={true}
                    style={{
                        height:200,
                        width:width,
                        borderColor:'red',
                        borderWidth:1
                    }}
                    aspectRatio={2}
                />}
            </View>
        )
    }
}