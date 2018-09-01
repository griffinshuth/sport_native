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
        this.props.dispatch({type:"NearBy/getNearbyUsers",payload:{}})
    }

    gotoUserDetails = (userinfo)=>{
        this.props.navigation.navigate("otherUserDetails",{userinfo})
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="附近的人"
                    navigation={this.props.navigation}
                />
                <ScrollView>
                    {
                        this.props.NearBy.users.map((item,index)=>{
                            return (<View>
                                <Flex>
                                    <Flex.Item>
                                        <Image source={{uri:item.headerimage}} style={{width:44,height:44}}></Image>
                                    </Flex.Item>
                                    <Flex.Item>{item.nickname}</Flex.Item>
                                </Flex>
                                <Flex>
                                    <Button>关注</Button>
                                    <Button>加为好友</Button>
                                    <Button onClick={()=>{this.gotoUserDetails(item)}}>查看</Button>
                                </Flex>
                            </View>)
                        })
                    }
                </ScrollView>
            </View>
        )
    }
}