import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter
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
        Toast.info(JSON.parse(result.data).results_recognition[0],1);
        console.log(result.data)
        var command = JSON.parse(result.data).results_recognition[0];
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
        BaiduASRModule.startListen();
        this.subscription = BaiduASRModuleEmitter.addListener(
            'onVoiceRecognize',
            this.onVoiceRecognize
        );
        this.getBrightness();
    }

    componentWillUnmount(){
        BaiduASRModule.endListen();
        this.subscription.remove();
    }

    render(){
        return (
            <View style={{flex:1}}>
                {this.state.valueSlide >= 50?<ToolBar title="绘图API" navigation={this.props.navigation}/>:null}
                <View>
                    <WhiteSpace/>
                    <Slider
                        style={{ marginLeft: 30, marginRight: 30 }}
                        defaultValue={Math.floor(this.state.brightness*100)}
                        min={0}
                        max={100}
                        onChange={(value)=>{
                            var t = value/100;
                            BaiduASRModule.brightness(t);
                            this.setState({valueSlide:value})
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