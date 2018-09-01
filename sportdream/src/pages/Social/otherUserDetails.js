import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter,
    Platform,
    TouchableHighlight,
    TouchableWithoutFeedback,
    Image,
    ScrollView,
    Dimensions,
    TextInput,
    KeyboardAvoidingView
} from 'react-native'
import {
    Flex,
    WingBlank,
    WhiteSpace,
    Slider,
    Toast,
    Badge,
    SegmentedControl,
    List,
    DatePicker,
    Picker,
    Button,
    TextareaItem,
    ImagePicker,
    Carousel
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {connect} from 'dva'

@connect(({appNS,NearBy})=>({appNS,NearBy}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {

        }
    }

    componentWillMount(){

    }

    render(){
        var {userinfo} = this.props.navigation.state.params;
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="附近的人"
                    navigation={this.props.navigation}
                />
                <ScrollView>
                    <View>
                        <Text>
                            {JSON.stringify(userinfo)}
                        </Text>
                    </View>
                </ScrollView>
            </View>
        )
    }
}