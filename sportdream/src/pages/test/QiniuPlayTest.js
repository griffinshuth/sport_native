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
import Orientation from 'react-native-orientation'

const QiniuPlayView = requireNativeComponent('QiniuPlayView', null);

var {height, width} = Dimensions.get('window');

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            playUrl:"",
            loading:true,
            isFullScreen:false,
            playerWidth:width,
            playerHeight:width*720/1280
        }
    }
    getLiveUrl = async()=>{
        var play = await post("/getRTMPPlayURL",{streamname:"singlematch_roomid"})
        this.setState({playUrl:play.url,loading:false})
    }

    componentWillMount(){
        var url = this.props.navigation.state.params.url;
        if(url){
            this.setState({playUrl:url,loading:false})
        }else{
            this.getLiveUrl();
        }
    }

    componentWillUnmount(){
        if(this.state.isFullScreen)
            Orientation.lockToPortrait();
    }

    render(){
        return (
            <View style={{position:"relative"}}>
                {this.state.loading?null:<QiniuPlayView
                    source={{
                        uri:this.state.playUrl,
                        timeout: 10 * 1000,
                        live:true,
                        hardCodec:false,
                    }}
                    started={true}
                    style={{
                        width:this.state.playerWidth,
                        height:this.state.playerHeight
                    }}
                    aspectRatio={2}
                />}
                <Button onClick={()=>{
                    this.props.navigation.goBack();
                }} type="ghost" size="small" style={{position:"absolute",top:10,right:10}}>关闭</Button>
                <Button onClick={()=>{
                    if(this.state.isFullScreen){
                        Orientation.lockToPortrait();
                        this.setState({playerWidth:width,playerHeight:width*720/1280,isFullScreen:false})
                    }else{
                        this.setState({playerWidth:height,playerHeight:width,isFullScreen:true})
                        Orientation.lockToLandscape();
                    }

                }} type="ghost" size="small" style={{position:"absolute",top:50,right:10}}>{this.state.isFullScreen?"退出全屏":"全屏"}</Button>
            </View>
        )
    }
}