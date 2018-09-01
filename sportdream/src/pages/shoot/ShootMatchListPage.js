import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter,
    Platform,
    TouchableHighlight,
    Image
} from 'react-native'
import {
    Flex,
    WingBlank,
    WhiteSpace,
    Slider,
    Toast,
    Badge,
    SegmentedControl,
    Card,
    List,
    Button,
    Modal
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {get,post} from '../../fetch'
import {connect} from 'dva'

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            selectedIndex:0,
            createdMatches:[],
            joinedMatches:[],
            nearbyMatches:[]
        }
    }

    componentWillMount(){
        this.loadMatch();
    }

    onChange = (e)=>{
        this.setState({selectedIndex:e.nativeEvent.selectedSegmentIndex})
    }

    loadMatch = async()=>{
        var token = this.props.appNS.token;
        var result  = await post("/getAllShootMatch",{token});
        this.setState({
            createdMatches:result.createdMatches,
            joinedMatches:result.joinedMatches,
            nearbyMatches:result.nearbyMatches
        });
    }

    joinMatch = async(matchuid)=>{
        var token = this.props.appNS.token;
        var result = await post("/joinShootMatch",{token,matchuid})
        if(!result.error){
            Toast.info("加入成功，记得按时比赛哟")
        }else{
            Toast.info(result.error);
        }
    }

    deleteMatch = async(matchuid)=>{
        var token = this.props.appNS.token;
        var result = await post("/deleteShootMatch",{token,matchuid})
        if(!result.error){
            Toast.info("删除成功")
        }else{
            Toast.info(result.error);
        }
    }

    gotoCreateShootMatchPage = ()=>{
        this.props.navigation.navigate('CreateShootMatchPage', {

        });
    }

    gotoBasketCourtShootRoomAndroid = (matchuid)=>{
        this.props.navigation.navigate('BasketCourtShootRoomAndroid', {
            matchuid:matchuid
        });
    }

    gotoNormalBasketCourtShootRoom = (matchuid)=>{
        this.props.navigation.navigate('NormalBasketCourtShootRoom', {
            matchuid:matchuid
        });
    }

    gotoSmartBasketStandShootRoom = (matchuid)=>{
        this.props.navigation.navigate('SmartBasketStandShootRoom', {
            matchuid:matchuid
        });
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="远程投篮比赛列表"
                    navigation={this.props.navigation}
                    headerRight={
                            <TouchableHighlight onPress={() => {
                                this.gotoCreateShootMatchPage()
                            }}>
                                <Image source={require('../../assets/images/add.png')} style={{width:28,height:28}}/>
                            </TouchableHighlight>
                    }
                />
                <View>
                    <SegmentedControl
                        style={{marginTop:1}}
                        values={['创建的比赛', '参加的比赛', '附近的比赛']}
                        selectedIndex = {this.state.selectedIndex}
                        onChange={this.onChange}
                    />
                    {this.state.selectedIndex == 0?<View>
                        {this.state.createdMatches.map((item,index) => {
                            var playercount = item.playercount+"人"
                            var durationtime = item.durationtime/60+"分钟"
                            var begintime = new Date(item.begintime).toLocaleDateString()
                            var state = "";
                            if(item.state == 0){
                                state = "未开始"
                            }else if(item.state == 1){
                                state = "进行中"
                            }else if(item.state == 2){
                                state = "比赛结束，视频未上传"
                            }else if(item.state == 3){
                                state = "比赛完成"
                            }
                            return (
                                <WingBlank>
                                    <WhiteSpace/>
                                <Card>
                                    <Card.Header
                                        title={playercount}
                                        extra={begintime}
                                    />
                                    <Card.Body>
                                        <List>
                                            <List.Item>
                                                <Flex>
                                                    {
                                                        item.members.map(function (userinfo) {
                                                            return <Flex.Item>
                                                                <Image style={{borderRadius:10, width: 80, height: 80 }} source={{uri:userinfo.headerimage}}/>
                                                            </Flex.Item>
                                                        })
                                                    }
                                                </Flex>
                                            </List.Item>
                                            <List.Item>
                                            <Flex>
                                                <Flex.Item><Button onClick={() => {
                                                    if(Platform.OS == "android"){
                                                        this.gotoBasketCourtShootRoomAndroid(item.shootmatch_uid)
                                                        return;
                                                    }
                                                    Modal.operation([
                                                    { text: '普通篮球场', onPress: () => {this.gotoNormalBasketCourtShootRoom(item.shootmatch_uid)} },
                                                    { text: '智能篮球架', onPress: () => {this.gotoSmartBasketStandShootRoom(item.shootmatch_uid)} },
                                                ])
                                                }} style={{margin:5}} type="ghost" size="small">比赛房间</Button></Flex.Item>
                                                <Flex.Item><Button onClick={()=>{
                                                    var matchuid = item.shootmatch_uid;
                                                    this.deleteMatch(matchuid);
                                                }} style={{margin:5}} type="ghost" size="small">删除</Button></Flex.Item>
                                                <Flex.Item><Button style={{margin:5}} type="ghost" size="small">回放</Button></Flex.Item>
                                            </Flex>
                                        </List.Item>
                                    </List>
                                    </Card.Body>
                                    <Card.Footer content={state} extra={durationtime} />
                                </Card>
                                </WingBlank>
                            )
                        })}
                    </View>:null}
                    {this.state.selectedIndex == 1?<View>
                        {this.state.joinedMatches.map((item,index) => {
                            var playercount = item.playercount+"人"
                            var durationtime = item.durationtime/60+"分钟"
                            var begintime = new Date(item.begintime).toLocaleDateString()
                            var state = "";
                            if(item.state == 0){
                                state = "未开始"
                            }else if(item.state == 1){
                                state = "进行中"
                            }else if(item.state == 2){
                                state = "比赛结束，视频未上传"
                            }else if(item.state == 3){
                                state = "比赛完成"
                            }
                            return (
                                <WingBlank>
                                    <WhiteSpace/>
                                    <Card>
                                        <Card.Header
                                            title={playercount}
                                            extra={begintime}
                                        />
                                        <Card.Body>
                                            <List>
                                                <List.Item>
                                                    <Flex>
                                                        {
                                                            item.members.map(function (userinfo) {
                                                                return <Flex.Item>
                                                                    <Image style={{borderRadius:10, width: 80, height: 80 }} source={{uri:userinfo.headerimage}}/>
                                                                </Flex.Item>
                                                            })
                                                        }
                                                    </Flex>
                                                </List.Item>
                                                <List.Item>
                                                    <Flex>
                                                        <Flex.Item><Button onClick={() => {
                                                            if(Platform.OS == "android"){
                                                                this.gotoBasketCourtShootRoomAndroid(item.shootmatch_uid)
                                                                return;
                                                            }
                                                            Modal.operation([
                                                            { text: '普通篮球场', onPress: () => {this.gotoNormalBasketCourtShootRoom(item.shootmatch_uid)} },
                                                            { text: '智能篮球架', onPress: () => {this.gotoSmartBasketStandShootRoom(item.shootmatch_uid)} },
                                                        ])
                                                        }} style={{margin:5}} type="ghost" size="small">比赛房间</Button></Flex.Item>
                                                        <Flex.Item><Button style={{margin:5}} type="ghost" size="small">退出</Button></Flex.Item>
                                                        <Flex.Item><Button style={{margin:5}} type="ghost" size="small">回放</Button></Flex.Item>
                                                    </Flex>
                                                </List.Item>
                                            </List>
                                        </Card.Body>
                                        <Card.Footer content={state} extra={durationtime} />
                                    </Card>
                                </WingBlank>
                            )
                        })}
                    </View>:null}
                    {this.state.selectedIndex == 2?<View>
                        {this.state.nearbyMatches.map((item,index) => {
                            var playercount = item.playercount+"人"
                            var durationtime = item.durationtime/60+"分钟"
                            var begintime = new Date(item.begintime).toLocaleDateString()
                            var state = "";
                            if(item.state == 0){
                                state = "未开始"
                            }else if(item.state == 1){
                                state = "进行中"
                            }else if(item.state == 2){
                                state = "比赛结束，视频未上传"
                            }else if(item.state == 3){
                                state = "比赛完成"
                            }
                            return (
                                <WingBlank>
                                    <WhiteSpace/>
                                    <Card>
                                        <Card.Header
                                            title={playercount}
                                            extra={begintime}
                                        />
                                        <Card.Body>
                                            <List>
                                                <List.Item>
                                                    <Flex>
                                                        {
                                                            item.members.map(function (userinfo) {
                                                                return <Flex.Item>
                                                                    <Image style={{borderRadius:10, width: 80, height: 80 }} source={{uri:userinfo.headerimage}}/>
                                                                </Flex.Item>
                                                            })
                                                        }
                                                    </Flex>
                                                </List.Item>
                                                <List.Item>
                                                    <Flex>
                                                        <Flex.Item><Button onClick={()=>{
                                                            var matchuid = item.shootmatch_uid;
                                                            this.joinMatch(matchuid);
                                                        }} style={{margin:5}} type="ghost" size="small">加入</Button></Flex.Item>
                                                        <Flex.Item><Button style={{margin:5}} type="ghost" size="small">回放</Button></Flex.Item>
                                                    </Flex>
                                                </List.Item>
                                            </List>
                                        </Card.Body>
                                        <Card.Footer content={state} extra={durationtime} />
                                    </Card>
                                </WingBlank>
                            )
                        })}
                    </View>:null}

                </View>
            </View>
        )
    }
}