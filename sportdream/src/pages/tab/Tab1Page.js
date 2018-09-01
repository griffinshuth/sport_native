import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    TextInput,
    Platform,
    ScrollView,
    Alert,
    TouchableHighlight
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast,
    Card,
    WingBlank,
    List,
    InputItem,
    SearchBar,
    Modal,
    Drawer,
    Tabs,
    Badge,
    NoticeBar,
    Carousel,
    Grid,
    Flex
} from 'antd-mobile'

import {NativeModules} from 'react-native'
var ChatModule = NativeModules.ChatModule;
var QiniuModule = NativeModules.QiniuModule;
var WiFiAPModule = NativeModules.WiFiAPModule;

import {
    NavigationActions,
    StackNavigator,
    addNavigationHelpers
} from 'react-navigation'
import {connect} from 'dva'
import ToolBar from '../../Components/ToolBar'
import emitter from '../../utils/SingleEventEmitter'

const createAction = type => payload => ({type,payload})
import {post,get} from '../../fetch'

const styles = StyleSheet.create({
    container:{
        flex:1,
    },
    icon:{
        width:32,
        height:32
    },
    scrollviewIos:{
        marginTop:-20
    },
    scrollviewAndroid:{

    },
    carouselStyle:{
        flexGrow: 1,
        alignItems: 'center',
        justifyContent: 'center',
        height: 200,
    }

})

@connect(({appNS,user,temp})=>({appNS,user,temp}))
export default class Main extends Component{
    constructor(props){
        super(props);
        this.state = {

        }
    }

    createTimeLine = ()=>{
        this.props.navigation.navigate("CreateTimeLinePage",{});
    }

    componentDidMount(){
        //监听二维码扫码事件
        emitter.on("scanQRCode",(msg)=>{
            //Toast.info(msg);
            //return;
            var arr = msg.split('&');
            if(arr[0] == "highlightserver"){
                var ip = arr[1];
                Toast.info(ip);
                if(Platform.OS != 'ios')
                    QiniuModule.h264Record(this.props.appNS.clientID,0,"haimeng",10000,ip);
                else
                    QiniuModule.gotoCameraOnStand(this.props.appNS.clientID,0,"haimeng",10000,ip);
                return;
            }else if(arr[0] == "playrtmpurl"){
                //Toast.info(arr[1]);
                setTimeout(()=>{
                    this.props.dispatch(NavigationActions.navigate({
                        routeName:'QiniuPlayTest',
                        params: {
                            url:arr[1]
                        },
                    }))
                },0)
            }
        })
    }


    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="首页"
                    headerLeft={<Image source={require('../../assets/images/qrcode.png')} style={{width:28,height:28}}/>}
                    navigation={this.props.navigation}
                    headerRight={
                        <Badge text={9}>
                        <TouchableHighlight onPress={
                            () => Modal.operation([
                                { text: '创建动态', onPress: () => {this.createTimeLine();} },
                                { text: '扫一扫', onPress: () => {} },
                            ])
                        }>
                        <Image source={require('../../assets/images/add.png')} style={{width:28,height:28}}/>
                        </TouchableHighlight>
                        </Badge>
                    } />
                    <ScrollView>
                        <Carousel
                            style={Platform.OS=='ios'?styles.scrollviewIos:styles.scrollviewAndroid}
                            autoplayTimeout={3}
                            selectedIndex={0}
                            autoplay
                            infinite
                            afterChange={this.onselectedIndexChange}
                        >
                            <View style={[styles.carouselStyle, { backgroundColor: 'red' }]}>
                                <Text>Carousel 1</Text>
                            </View>
                            <View style={[styles.carouselStyle, { backgroundColor: 'blue' }]}>
                                <Text>Carousel 2</Text>
                            </View>
                            <View style={[styles.carouselStyle, { backgroundColor: 'yellow' }]}>
                                <Text>Carousel 3</Text>
                            </View>
                            <View style={[styles.carouselStyle, { backgroundColor: 'black' }]}>
                                <Text>Carousel 4</Text>
                            </View>
                        </Carousel>
                        <WingBlank>
                        <Flex style={{margin:10}}>
                            <Flex.Item>
                                <TouchableHighlight onPress={()=>{
                                    this.props.navigation.navigate("TimeLinePage",{})
                                }}>
                                <View style={{flex:1,alignItems:'center'}}>
                                    <Image
                                        source={require("../../assets/images/menu/timeline.png")}
                                        style={{width:22,height:22}}
                                    />
                                    <WhiteSpace/>
                                    <Text>运动圈</Text>
                                </View>
                                </TouchableHighlight>
                            </Flex.Item>
                            <Flex.Item>
                                <View style={{flex:1,alignItems:'center'}}>
                                    <Image
                                        source={require("../../assets/images/menu/video.png")}
                                        style={{width:22,height:22}}
                                    />
                                    <WhiteSpace/>
                                    <Text>视频</Text>
                                </View>
                            </Flex.Item>
                            <Flex.Item>
                                <View style={{flex:1,alignItems:'center'}}>
                                    <Image
                                        source={require("../../assets/images/menu/loginreward.png")}
                                        style={{width:22,height:22}}
                                    />
                                    <WhiteSpace/>
                                    <Text>登录奖励</Text>
                                </View>
                            </Flex.Item>
                            <Flex.Item>
                                <TouchableHighlight onPress={()=>{
                                    this.props.navigation.navigate("NearbyUsers",{})
                                }}>
                                <View style={{flex:1,alignItems:'center'}}>
                                    <Image
                                        source={require("../../assets/images/menu/friends.png")}
                                        style={{width:22,height:22}}
                                    />
                                    <WhiteSpace/>
                                    <Text>附近</Text>
                                </View>
                                </TouchableHighlight>
                            </Flex.Item>
                        </Flex>
                            <Flex style={{margin:10}}>
                                <Flex.Item>
                                    <View style={{flex:1,alignItems:'center'}}>
                                        <Image
                                            source={require("../../assets/images/menu/task.png")}
                                            style={{width:22,height:22}}
                                        />
                                        <WhiteSpace/>
                                        <Text>任务</Text>
                                    </View>
                                </Flex.Item>
                                <Flex.Item>
                                    <View style={{flex:1,alignItems:'center'}}>
                                        <Image
                                            source={require("../../assets/images/menu/rank.png")}
                                            style={{width:22,height:22}}
                                        />
                                        <WhiteSpace/>
                                        <Text>排行榜</Text>
                                    </View>
                                </Flex.Item>
                                <Flex.Item>
                                    <View style={{flex:1,alignItems:'center'}}>
                                        <Image
                                            source={require("../../assets/images/menu/activity.png")}
                                            style={{width:22,height:22}}
                                        />
                                        <WhiteSpace/>
                                        <Text>活动</Text>
                                    </View>
                                </Flex.Item>
                                <Flex.Item>
                                    <View style={{flex:1,alignItems:'center'}}>
                                        <Image
                                            source={require("../../assets/images/menu/shop.png")}
                                            style={{width:22,height:22}}
                                        />
                                        <WhiteSpace/>
                                        <Text>商城</Text>
                                    </View>
                                </Flex.Item>
                            </Flex>
                        </WingBlank>
                        <WingBlank>
                        <Card>
                            <Card.Header
                                title="热门"
                                extra="更多"
                            />
                            <Card.Body>
                                <List>
                                    <List.Item>
                                        <Button>动态</Button>
                                    </List.Item>
                                </List>
                            </Card.Body>
                            <Card.Footer content="时间" extra="联系" />
                        </Card>
                        </WingBlank>
                    </ScrollView>
            </View>
        )
    }
}
