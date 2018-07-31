import React,{Component} from 'react'
import {
    AppRegistry,
    Dimensions,
    StyleSheet,
    Text,
    View,
    Animated,
    StatusBarIOS,
    TouchableOpacity,
    TouchableWithoutFeedback,
} from 'react-native';

import ToolBar from '../../Components/ToolBar'
var screen = require('Dimensions').get('window');
import Recorder from 'react-native-screcorder'

const styles = StyleSheet.create({
    wrapper: {
        flex: 1
    },

    barWrapper: {
        width: screen.width,
        height: 10,
        backgroundColor: "black",
        opacity: 0.3
    },

    barGauge: {
        width: 0,
        height: 10,
        backgroundColor: "red"
    },

    controls: {
        position: 'absolute',
        bottom: 50,
        width: screen.width,
        flexDirection: 'row',
        flexWrap: "wrap",
        justifyContent: 'space-around',
        alignItems: 'center',
        backgroundColor: 'transparent',
        opacity: 0.6
    },

    controlBtn: {
        backgroundColor: "white",
        padding: 20,
        opacity: 0.8,
        borderRadius: 5,
        marginBottom: 10
    },

    infoBtn: {
        backgroundColor: "#2ecc71",
        opacity: 0.8,
        padding: 10,
        position: 'absolute',
        top: 20,
        right: 20,
        opacity: 0.7,
        borderRadius: 5
    },

    infoBtnText: {
        color: "white"
    }
});

export default class App extends Component{
    constructor(props){
        super(props);
        console.log(Recorder);
        this.state = {
            device: "front",
            recording: false,
            nbSegments: 0,
            barPosition: new Animated.Value(0),
            currentDuration: 0,
            maxDuration: 30000,
            limitReached: false,
            config: {
                flashMode: Recorder.constants.SCFlashModeOff,
                autoSetVideoOrientation: false,
                video: {
                    enabled: true,
                    format: 'MPEG4',
                    bitrate: 500000,
                    timescale: 1, // Higher than 1 makes a slow motion, between 0 and 1 makes a timelapse effect
                    quality: "MediumQuality", // HighestQuality || MediumQuality || LowQuality
                    filters: [
                        /*{
                          "CIfilter": "CIColorControls",
                          "animations": [{
                            "name": "inputSaturation",
                            "startValue": 100,
                            "endValue": 0,
                            "startTime": 0,
                            "duration": 0.5
                          }]
                        },*/
                        /*{"file": "b_filter"},*/
                        /*{"CIfilter":"CIColorControls", "inputSaturation": 0},
                        {"CIfilter":"CIExposureAdjust", "inputEV": 0.7}*/
                    ]
                },
                audio: {
                    enabled: true,
                    bitrate: 128000, // 128kbit/s
                    channelsCount: 1, // Mono output
                    format: "MPEG4AAC",
                    quality: "HighestQuality" // HighestQuality || MediumQuality || LowQuality
                }
            }
        }
    }
    componentDidMount() {
        //StatusBarIOS.setHidden(true, "slide");
    }
    startBarAnimation = ()=> {
        this.animRunning = true;
        this.animBar = Animated.timing(
            this.state.barPosition,
            {
                toValue: screen.width,
                duration: this.state.maxDuration - this.state.currentDuration
            }
        );
        this.animBar.start(() => {
            // The video duration limit has been reached
            if (this.animRunning) {
                this.finish();
            }
            });
    }

    resetBarAnimation = ()=> {
        Animated.spring(this.state.barPosition, {toValue: 0}).start();
    }

    stopBarAnimation = ()=> {
        this.animRunning = false;
        if (this.animBar)
            this.animBar.stop();
    }

    record = ()=> {
        if (this.state.limitReached) return;
        this.refs.recorder.record();
        this.startBarAnimation();
        this.setState({recording: true});
    }

    pause = (limitReached)=> {
        if (!this.state.recording) return;
        this.refs.recorder.pause();
        this.stopBarAnimation();
        this.setState({recording: false, nbSegments: ++this.state.nbSegments});
    }

    finish = ()=> {
        this.stopBarAnimation();
        this.refs.recorder.pause();
        this.setState({recording: false, limitReached: true, nbSegments: ++this.state.nbSegments});
    }

    reset = ()=> {
        this.resetBarAnimation();
        this.refs.recorder.removeAllSegments();
        this.setState({
                      recording: false,
                      nbSegments: 0,
                      currentDuration: 0,
                      limitReached: false
                  });
    }

    preview = ()=> {
        this.refs.recorder.save((err, url) => {
            console.log('url = ', url);
            this.props.navigation.navigate('ReactNativeVideoTest', {
                url:url
            });
        });
    }

    setDevice = ()=> {
        var device = (this.state.device == "front") ? "back" : "front";
        this.setState({device: device});
    }

    toggleFlash = ()=> {
        if (this.state.config.flashMode == Recorder.constants.SCFlashModeOff) {
            this.state.config.flashMode = Recorder.constants.SCFlashModeLight;
        } else {
            this.state.config.flashMode = Recorder.constants.SCFlashModeOff;
        }
            this.setState({config: this.state.config});
    }

    onRecordDone = ()=> {
        this.setState({nbSegments: 0});
    }

    onNewSegment = (segment)=> {
        console.log('segment = ', segment);
        this.state.currentDuration += segment.duration * 1000;
    }

    renderBar = ()=> {
        return (
            <View style={styles.barWrapper}>
                <Animated.View style={[styles.barGauge, {width: this.state.barPosition}]}/>
            </View>
        );
    }

render() {
    var bar     = this.renderBar();
    var control = null;

    if (!this.state.limitReached) {
        control = (
            <TouchableOpacity onPressIn={this.record} onPressOut={this.pause} style={styles.controlBtn}>
                <Text>Record</Text>
            </TouchableOpacity>
        );
    }
        return (
            <View style={styles.wrapper}>
                <ToolBar title="短视频拍摄" navigation={this.props.navigation}/>
                <Recorder
                    ref="recorder"
                    config={this.state.config}
                    device={this.state.device}
                    onNewSegment={this.onNewSegment}
                    style={styles.wrapper}>
                    {bar}
                    <View style={styles.infoBtn}>
                        <Text style={styles.infoBtnText}>{this.state.nbSegments}</Text>
                    </View>
                    <View style={styles.controls}>
                        {control}
                        <TouchableOpacity onPressIn={this.reset} style={styles.controlBtn}>
                            <Text>Reset</Text>
                        </TouchableOpacity>
                        <TouchableOpacity onPress={this.preview} style={styles.controlBtn}>
                            <Text>Preview</Text>
                        </TouchableOpacity>
                        <TouchableOpacity onPress={this.toggleFlash} style={styles.controlBtn}>
                            <Text>Flash</Text>
                        </TouchableOpacity>
                        <TouchableOpacity onPress={this.setDevice} style={styles.controlBtn}>
                            <Text>Switch</Text>
                        </TouchableOpacity>
                    </View>
                </Recorder>
            </View>
        );
    }


}