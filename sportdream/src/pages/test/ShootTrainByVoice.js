import React from 'react'
import {
    View,
    Text,
    StyleSheet,
    NativeModules,
    DeviceEventEmitter
} from 'react-native'

import {
    Toast
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
var BaiduASRModule = NativeModules.BaiduASRModule;

const styles = StyleSheet.create({
    container:{
        flex:1
    }
});

export default class App extends React.Component{
    componentDidMount(){
        this.onVoiceRecognize_handler = DeviceEventEmitter.addListener('onVoiceRecognize', function(result) {
            var command = result.RecognizeResult;
            Toast.info(command);
            BaiduASRModule.speak(command);
        });
        BaiduASRModule.init();
        BaiduASRModule.initTTS();
    }
    componentWillUnmount(){
        BaiduASRModule.destroy();
        BaiduASRModule.destroyTTS();
        this.onVoiceRecognize_handler.remove();
    }
    render(){
        return (
            <View style={styles.container}>
                <ToolBar title="android语音识别" navigation={this.props.navigation}/>
            </View>
        )
    }
}
