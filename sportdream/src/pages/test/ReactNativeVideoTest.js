import React,{Component} from 'react'
import {
    AppRegistry,
    Dimensions,
    StyleSheet,
    Text,
    View,
    Animated,
    TouchableOpacity,
    TouchableWithoutFeedback,
    NativeModules,
    NativeEventEmitter
} from 'react-native';
import {
    Toast,
    Button,
    WhiteSpace
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import Video from 'react-native-video'
var QiniuModule = NativeModules.QiniuModule;
var AccompanyModule = NativeModules.AccompanyModule;
var VideoGPUFilterModule = NativeModules.VideoGPUFilterModule;
const QiniuModuleEmitter = new NativeEventEmitter(QiniuModule);
const VideoGPUFilterModuleEmitter = new NativeEventEmitter(VideoGPUFilterModule);
var domain = "http://grassroot.qiniudn.com/"

const styles = StyleSheet.create({
    wrapper: {
        flex: 1
    }
});

export default class App extends Component{
    constructor(props){
        super(props);
        this.state = {
            paused:true,
            player_text:"播放",
            filterProgress:0,
            video_url:this.props.navigation.state.params.url
        }
    }
    play = ()=>{
        var text = !this.state.paused?"暂停":"播放"
        this.setState({paused:!this.state.paused,player_text:text})
    }
    componentDidMount(){
        this.uploadProgress_subscription = QiniuModuleEmitter.addListener(
            'uploadProgress',
            (event) => console.log(event)
        );
        this.FilterProgress_subscription = VideoGPUFilterModuleEmitter.addListener("FilterProgress",(event)=>{
            var percent = event.percent;
            percent = percent*100;
            percent = percent.toFixed(2);
            this.setState({filterProgress:percent});
        })
    }
    componentWillUnmount(){
        this.uploadProgress_subscription.remove();
        this.FilterProgress_subscription.remove();
    }
    publish = async()=>{
        var path = this.state.video_url.substring(7);
        var result = await QiniuModule.upload(path);
        var url = domain + result.name;
        console.log(url);
        Toast.info("上传成功");
    }
    accompany = async()=>{
        Toast.loading("处理中", 0);
        var result = await AccompanyModule.addAccompany(this.state.video_url,"bgm");
        console.log("accompany:",result);
        this.setState({video_url:result.url})
        Toast.hide();
        Toast.info("处理完成",1)
    }
    addEffect = async()=>{
        Toast.loading("处理中", 0);
        var result = await VideoGPUFilterModule.processFilters(this.state.video_url);
        console.log("addEffect:",result);
        this.setState({video_url:result.url})
        Toast.hide();
        Toast.info("处理完成",1)
    }
    render(){
        return (<View style={styles.wrapper}>
            <ToolBar title="短视频录制" navigation={this.props.navigation}/>
            <Video
                source={{uri: this.state.video_url}}
                style={styles.wrapper}
                muted={false}
                resizeMode="cover"
                paused={this.state.paused}
                repeat={true}/>
            <WhiteSpace/>
            <Button onClick={this.play}>{this.state.player_text}</Button>
            <WhiteSpace/>
            <Button onClick={this.accompany}>增加伴奏</Button>
            <WhiteSpace/>
            <Button onClick={this.addEffect}>增加特效</Button>
            <WhiteSpace/>
            <Button onClick={this.publish}>发布</Button>
        </View>)
    }
}