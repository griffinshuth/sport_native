import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter,
    Platform
} from 'react-native'
import {
    Flex,
    WingBlank,
    WhiteSpace,
    Slider,
    Toast
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
var BaiduASRModule = NativeModules.BaiduASRModule;
const BaiduASRModuleEmitter = new NativeEventEmitter(BaiduASRModule);

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            shoot:0,
            score:0,
            brightness:0.5,
            valueSlide:100
        }
    }

    getBrightness = async()=>{
        var b = await BaiduASRModule.getBrightness();
        this.setState({brightness:b.brightness})
    }

    onVoiceRecognize = (result)=>{
        if(Platform.OS == 'ios'){
            var command = JSON.parse(result.data).results_recognition[0];
        }else{
            var command = result.RecognizeResult;
        }
        Toast.info(command);
        if(command == "sorry"){
            this.state.shoot++;
            this.setState({shoot:this.state.shoot})
            BaiduASRModule.speak(this.state.shoot+"中"+this.state.score)
        }
        if(command == "ok"){
            this.state.score++;
            this.state.shoot++;
            this.setState({score:this.state.score,shoot:this.state.shoot})
            BaiduASRModule.speak(this.state.shoot+"中"+this.state.score)
        }
    }

    componentDidMount(){
        if(Platform.OS == 'ios'){
            BaiduASRModule.startListen();
            this.getBrightness();
        }else{
            BaiduASRModule.init();
            BaiduASRModule.initTTS();
        }

        this.subscription = BaiduASRModuleEmitter.addListener(
            'onVoiceRecognize',
            this.onVoiceRecognize
        );
    }

    componentWillUnmount(){
        if(Platform.OS == 'ios'){
            BaiduASRModule.endListen();
        }else{
            BaiduASRModule.destroy();
            BaiduASRModule.destroyTTS();
        }
        this.subscription.remove();
    }

    render(){
        return (
            <View style={{flex:1}}>
                {this.state.valueSlide >= 50?<ToolBar title="智能投篮训练" navigation={this.props.navigation}/>:null}
                <View>
                    <WhiteSpace/>
                    <Slider
                        style={{ marginLeft: 30, marginRight: 30 }}
                        defaultValue={Math.floor(this.state.brightness*100)}
                        min={0}
                        max={100}
                        onChange={(value)=>{
                            var t = value/100;
                            this.setState({valueSlide:value})
                            if(Platform.OS == 'ios'){
                                BaiduASRModule.brightness(t);
                            }
                        }}
                    />
                    <WhiteSpace/>
                    <Flex>
                        <Flex.Item><Text>{"投篮："+this.state.shoot}</Text></Flex.Item>
                        <Flex.Item><Text>{"得分"+this.state.score}</Text></Flex.Item>
                    </Flex>
                </View>
            </View>
        )
    }

}