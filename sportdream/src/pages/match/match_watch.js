import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    Image
} from 'react-native'
import {
    Flex,
    WhiteSpace,
    WingBlank,
    Button,
    List,
    Tabs,
    Badge,
    ActivityIndicator
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import io from 'socket.io-client'
import {clientEvent,serverEvent,permissionType,admin_op} from '../../utils/socketEvent'
import {get, post,serverurl} from '../../fetch'

const tabs = [
    { title: '文字直播' },
    { title: '聊天室' },
    { title: '数据' },
    { title: '互动' },
    { title: '竞猜' },
    { title: '游戏' },
    { title: '视频' },
    { title: '图片' },
];

@connect(({appNS,user})=>({appNS,user}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            matchinfo:null,
            loading:true,
        }
    }

    second2time = (second)=>{
        var m_text = "";
        var s_text = "";
        var m = Math.floor(second/60);
        var s = second%60;
        if(minute = 0){
            m_text = "00"
        }else{
            m_text = m;
        }
        if(s<10){
            s_text = "0"+s;
        }else{
            s_text = s;
        }

        var result = m_text+":"+s_text;
        if(m == 0 && s == 0){
            result = "结束"
        }
        return result;
    }

    watchGame = ()=>{
        var clientID = this.props.appNS.clientID;
        var uid = this.props.user.uid;
        this.socket = io(serverurl,{
            //transports: ['websocket'],
        });
        this.socket.on("reconnect",()=>{
            console.log("reconnect")
        })

        this.socket.on(clientEvent.initRoomInfo,(data)=>{
            this.setState({loading:false,matchinfo:data.info})
            console.log(this.state.matchinfo);
        })

        this.socket.on(clientEvent.updateTime,(data)=>{
            if(this.state.matchinfo){
                this.state.matchinfo.room.currentsection = data.currentsection;
                this.state.matchinfo.room.currentsectiontime = data.currentsectiontime;
                this.setState({matchinfo:this.state.matchinfo})
            }
        })

        this.socket.on(clientEvent.updateScore,(data)=>{
            if(this.state.matchinfo){
                this.state.matchinfo.room.team1currentscore = data.team1currentscore;
                this.state.matchinfo.room.team2currentscore = data.team2currentscore;
                this.setState({matchinfo:this.state.matchinfo})
            }
        })

        this.socket.emit(serverEvent.login,{uuid:uid,clientID:clientID},(data)=>{
            var room_uid = this.props.navigation.state.params.room_uid;
            this.socket.emit(serverEvent.enterRoom,{room_uid:room_uid},(data)=>{

            })
        })

    }

    componentDidMount(){
        this.watchGame();
    }

    componentWillUnmount(){
        this.socket.disconnect();
    }

    render(){
        var team1 = this.props.navigation.state.params.team1;
        var team2 = this.props.navigation.state.params.team2;
        return (
            <View style={{flex:1}}>
                <ToolBar title="技术统计" navigation={this.props.navigation} />
                {
                    this.state.loading?<ActivityIndicator/>:<View style={{flex:1}}><WingBlank>
                            <WhiteSpace/>
                            <Flex>
                                <Flex  justify="center" direction="column">
                                    <Text style={{color:'#aaa',fontSize:12}}>BONUS</Text>
                                    <WhiteSpace/>
                                    <Badge text="攻">
                                        <Image style={{width:80,height:80}} source={{uri:team1.logo}}/>
                                    </Badge>
                                    <Text>{team1.name}</Text>
                                    <Flex>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                    </Flex>
                                </Flex>
                                <Flex.Item>
                                    <Flex justify="center" direction="column">
                                        <Text>{this.state.matchinfo.room.team1currentscore+":"+this.state.matchinfo.room.team2currentscore}</Text>
                                        <WhiteSpace/>
                                        <Text>{"第"+this.state.matchinfo.room.currentsection+"节"}</Text>
                                        <WhiteSpace size="xs"/>
                                        <Text>{this.second2time(this.state.matchinfo.room.currentsectiontime)}</Text>
                                        <WhiteSpace/>
                                        <Text style={{fontSize:25,fontWeight:'bold'}}>{this.state.matchinfo.room.currentattacktime}</Text>
                                        <WhiteSpace/>
                                        <Button  size="small" type="ghost">视频直播</Button>
                                    </Flex>
                                </Flex.Item>
                                <Flex  justify="center" direction="column">
                                    <Text style={{color:'#aaa',fontSize:12}}>BONUS</Text>
                                    <WhiteSpace/>
                                    <Badge text="守">
                                        <Image style={{width:80,height:80}} source={{uri:team2.logo}}/>
                                    </Badge>
                                    <Text>{team2.name}</Text>
                                    <Flex>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                        <Flex.Item style={{height:5,marginRight:1,backgroundColor:'green'}}></Flex.Item>
                                    </Flex>
                                </Flex>
                            </Flex>
                            <WhiteSpace/>
                        </WingBlank>
                        <View style={{ flex: 1}}>
                    <Tabs tabs={tabs} initialPage={1}>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 1 tab</Text>
                    </View>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 2 tab</Text>
                    </View>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 3 tab</Text>
                    </View>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 4 tab</Text>
                    </View>
                    <View style={{flex:1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 5 tab</Text>
                    </View>
                    <View style={{flex:1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 6 tab</Text>
                    </View>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 7 tab</Text>
                    </View>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 8 tab</Text>
                    </View>
                    <View style={{flex:1,alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff' }}>
                    <Text>Content of 9 tab</Text>
                    </View>
                    </Tabs>
                    </View>
                    </View>
                }
            </View>
        )
    }
}