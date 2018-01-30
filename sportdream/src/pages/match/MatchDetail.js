import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    ScrollView,
    Image
} from 'react-native'
import {
    List,
    Toast,
    ActivityIndicator,
    Flex,
    Button,
    WhiteSpace,
    Badge,
    Modal,
    Steps,
    WingBlank,
    Grid,
    Accordion,
    Picker,
    Card
} from 'antd-mobile'

import ToolBar from '../../Components/ToolBar'
import {get,post} from '../../fetch'
import type2text from '../../utils/Type2Text'
import {NavigationActions} from 'react-navigation'
import emitter from '../../utils/SingleEventEmitter'

const leagueType = [

    {label:'车轮战',value:"1"},
    {label:'杯赛',value:"2"},
    {label:'循环赛',value:"3"},
    {label:'循环+杯赛',value:"4"},
    {label:'小组+杯赛',value:'5'},
    {label:'自定义赛程',value:'6'}

]

@connect(({user,appNS}) => ({user,appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            isloaded:false,
            matchinfo:{},
            headerimage:null,
            players:[], //{id:-1,icon:"",text:""}
            showid:null,
            choose_leaguetype:["3"],
        }
    }

    getPlayerInfo = (uid) => {
        for(var i=0;i<this.state.players.length;i++){
            if(uid == this.state.players[i].id){
                return this.state.players[i];
            }
        }
    }

    loadMatchDetail = async(showid)=>{
        var result = await post("/getMatchDetailByShowId",{showid:showid})
        var headerimage = await post("/getUserHeaderImage",{uid:result.matchinfo.total.create_useruid})
        var players = await post("/getPlayersOfStreetMatch",{showid:showid});
        var temp_players = [];
        for(var i=0;i<players.players.length;i++){

                temp_players.push({id:players.players[i].id,icon:players.players[i].image,text:players.players[i].nickname})

        }
        this.setState({
            matchinfo:result.matchinfo,
            isloaded:true,
            headerimage:headerimage.headerimage,
            players:temp_players,
            showid:showid
        })
    }

    joinmatch = async() => {
        Modal.alert(this.props.user.nickname, '是否加入比赛？', [
            { text: 'Cancel', onPress: () => console.log('cancel') },
            { text: 'Ok', onPress: async() => {

                var result = await post("/joinmatch",{token:this.props.appNS.token,showid:this.state.showid})
                if(result.error){
                    Toast.info(result.errorinfo);
                }else{
                    this.loadMatchDetail(this.state.showid);
                }
            } },
        ])
    }

    createTempTeams = async() => {
        var result = await post('/createTempTeams',{token:this.props.appNS.token,showid:this.state.showid})
        if(result.error){
            Toast.info(result.errorinfo);
        }else{
            this.loadMatchDetail(this.state.showid)
        }
    }

    onUpdateTeamsLogoAndName = (msg)=>{
        var temp_teams = this.state.matchinfo.detail.match_teams;
        console.log(temp_teams);
        //Toast.info(JSON.stringify(msg));
        temp_teams[msg.teamid].name = msg.name;
        temp_teams[msg.teamid].logo = msg.logo;
        this.setState({matchinfo:this.state.matchinfo})
    }

    componentDidMount(){
        var showid = this.props.navigation.state.params.showid;
        setTimeout(()=>{
            this.loadMatchDetail(showid);
        },0)

        emitter.on("updateTeamsLogoAndName",this.onUpdateTeamsLogoAndName);
    }
    componentWillMount(){
        emitter.removeListener("updateTeamsLogoAndName",this.onUpdateTeamsLogoAndName);
    }

    createInitSchedule = async()=>{
        var result = await post("/createInitSchedule",{
            token:this.props.appNS.token,
            showid:this.state.showid,
            league_type:this.state.choose_leaguetype
        });
        if(result.error){
            Toast.info(result.errorinfo);
        }else{
            this.loadMatchDetail(this.state.showid);
        }
    }

    gotoCreateLogoName = (teamid)=>{
        this.props.dispatch(NavigationActions.navigate({
            routeName:'createTeamLogoName',
            params: {showid:this.state.showid,teamid:teamid},
        }))
    }

    render(){
        if(this.state.isloaded){
            var matchid = "比赛ID：" + this.state.matchinfo.total.match_showid;
            var creater = "创建者：" + this.state.matchinfo.total.create_useruid;
            var cityname = "所在城市：" + this.state.matchinfo.total.city_name;
            var createdate = "创建日期：" + new Date(this.state.matchinfo.total.createtime).toLocaleDateString();
            var createtime = "创建时间：" + new Date(this.state.matchinfo.total.createtime).toLocaleTimeString();
            var sporttype = this.state.matchinfo.total.sport_type;
            var temp_teams = this.state.matchinfo.detail.match_teams;
            var schedules = this.state.matchinfo.detail.match_games;
            console.log(schedules);
            console.log(temp_teams);
            var self = this;
        }
        return (
            <View style={{flex:1}}>
                <ToolBar title="比赛详情" navigation={this.props.navigation} />
                <ScrollView style={{flex:1}}>
                    {this.state.isloaded?<View style={{flex:1}}>
                        <Accordion>
                            <Accordion.Panel header="1.基本信息">
                                <List>
                                    <List.Item>
                                        <Flex>
                                            <Text>{matchid}</Text>
                                            <Button style={{marginLeft:10}} size="small" type="ghost">关注</Button>
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>{creater}</Text>
                                            <Image source={{uri:this.state.headerimage}}
                                                   style={{marginLeft:10,width:32,height:32,borderRadius:16,borderWidth:2,borderColor:'#ccc'}} />
                                            <Button style={{marginLeft:10}} size="small" type="ghost">加为好友</Button>
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>{type2text.getSportType(sporttype)}</Text>
                                            <Image source={type2text.getSportImage(sporttype)}
                                                   style={{marginLeft:10,width:22,height:22}} />
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>{cityname}</Text>
                                            <Image source={require("../../assets/images/location.png")}
                                                   style={{marginLeft:10,width:22,height:22}} />
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>{createdate}</Text>
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>{createtime}</Text>
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>{type2text.getMatchType(this.state.matchinfo.total.match_type)}</Text>
                                        </Flex>
                                    </List.Item>
                                </List>
                            </Accordion.Panel>
                            <Accordion.Panel header="2.比赛规则">
                                <List>
                                    <List.Item>
                                        <Flex>
                                            <Text>首发：{this.state.matchinfo.detail.match_rule.startup_num}</Text>
                                        </Flex>
                                    </List.Item>
                                    <List.Item>
                                        <Flex>
                                            <Text>赢球方式：{type2text.getHowWinType(this.state.matchinfo.detail.match_rule.howwin)}</Text>
                                        </Flex>
                                    </List.Item>
                                    {this.state.matchinfo.detail.match_rule.howwin == 2?<List.Item>
                                        <Flex>
                                            <Text>单节时间：{this.state.matchinfo.detail.match_rule.sectiontime}分钟</Text>
                                        </Flex>
                                    </List.Item>:null}
                                    {this.state.matchinfo.detail.match_rule.howwin == 2?<List.Item>
                                        <Flex>
                                            <Text>分几节：{this.state.matchinfo.detail.match_rule.sectionnum}节</Text>
                                        </Flex>
                                    </List.Item>:null}
                                    {this.state.matchinfo.detail.match_rule.howwin == 1?<List.Item>
                                        <Flex>
                                            <Text>分制：{this.state.matchinfo.detail.match_rule.pointwin}分</Text>
                                        </Flex>
                                    </List.Item>:null}
                                    <List.Item>
                                        <Flex>
                                            <Text>场地：{type2text.getCourtType(this.state.matchinfo.detail.match_rule.courttype)}</Text>
                                        </Flex>
                                    </List.Item>
                                </List>
                            </Accordion.Panel>
                            <Accordion.Panel header="3.邀请球员(进行中)">
                                <View>
                                    <List>
                                        <List.Item>
                                            <Flex>
                                                <Text>{type2text.getMatchState(this.state.matchinfo.total.match_state)}</Text>
                                                <Button
                                                    onClick={this.joinmatch}
                                                    style={{marginLeft:20}} size="small" type="ghost">邀请加入比赛</Button>
                                            </Flex>
                                        </List.Item>
                                    </List>
                                    <Flex>
                                        <Flex.Item><Button>比赛二维码</Button></Flex.Item>
                                        <Flex.Item><Button>扫一扫</Button></Flex.Item>
                                    </Flex>
                                    <Flex justify="center" wrap="wrap">
                                        {
                                            this.state.players.map(function (item,index) {
                                                return <View style={{marginTop:20,marginBottom:20,width:70,height:80,alignItems:'center'}} key={index}>
                                                    <Badge text={index+""}><Image source={{uri:item.icon}}
                                                                                  resizeMode="contain"
                                                                                  style={{
                                                                                      width:44,
                                                                                      height:44
                                                                                  }} /></Badge>
                                                    <Text>{item.text}</Text>
                                                    <Button style={{marginLeft:5,marginRight:5,marginTop:5}} size="small" type="ghost">删除</Button>
                                                </View>
                                            })
                                        }
                                    </Flex>
                                </View>
                            </Accordion.Panel>
                            <Accordion.Panel header="4.临时球队(未开始)">
                                <View>
                                <Button onClick={this.createTempTeams}>创建临时球队</Button>
                                <WingBlank size="lg">
                                    {
                                        temp_teams.map((item,index) => {
                                            return (
                                                <View key={index}>
                                                    <WhiteSpace size="lg" />
                                                    <Card>
                                                        <Card.Header
                                                            title={
                                                                <Flex>
                                                                    {temp_teams[index].logo?<Image source={{uri:temp_teams[index].logo}} style={{width:60,height:60}} />
                                                                        :<Button onClick={()=>{this.gotoCreateLogoName(temp_teams[index].teamid)}} size="small" type="ghost">生成队名</Button>}
                                                                    {temp_teams[index].name?<Text style={{marginLeft:10}}>{temp_teams[index].name}</Text>:null}
                                                                </Flex>
                                                            }
                                                            extra={"战绩"}
                                                        />
                                                        <Card.Body>
                                                            <Flex justify="center" wrap="wrap">
                                                                {
                                                                    item.members.map(function (uid,playerindex) {
                                                                        return (
                                                                            <View style={{width:65,alignItems:'center'}} key={playerindex}>
                                                                                <Image source={{uri:self.getPlayerInfo(uid).icon}}
                                                                                       resizeMode="stretch"
                                                                                       style={{
                                                                                           width:44,
                                                                                           height:60
                                                                                       }} />
                                                                                <Text>{self.getPlayerInfo(uid).text}</Text>
                                                                                <Button style={{marginLeft:5,marginRight:5,marginTop:5}} size="small" type="ghost">离队</Button>
                                                                            </View>
                                                                        )
                                                                    })
                                                                }
                                                            </Flex>
                                                        </Card.Body>
                                                        <Card.Footer content="" extra={""} />
                                                    </Card>
                                                    <WhiteSpace/>
                                                </View>
                                            )
                                        })
                                    }
                                </WingBlank>
                                </View>
                            </Accordion.Panel>
                            <Accordion.Panel header="5.赛制">
                                <List>
                                    <Picker
                                        data={leagueType}
                                        title="选择赛制"
                                        cols={1}
                                        extra="请选择(可选)"
                                        value={this.state.choose_leaguetype}
                                        onChange={v=>{this.setState({choose_leaguetype:v})}}
                                    >
                                        <List.Item arrow="horizontal">赛制</List.Item>
                                    </Picker>
                                </List>
                            </Accordion.Panel>
                            <Accordion.Panel header="6.赛程(未开始)">
                                <View>
                                    <List>
                                    <Button onClick={this.createInitSchedule}>生成赛程</Button>
                                    {
                                        schedules.map((item,index)=>{
                                            console.log(item);
                                            console.log(temp_teams[item.teamID1])
                                            return <List.Item key={index} onClick={()=>{
                                                this.props.dispatch(NavigationActions.navigate({
                                                    routeName:'MatchGameList',
                                                    params: {schedule_uid:item.schedule_uid,matchid:this.state.showid},
                                                }))
                                            }}>
                                                <Flex>
                                                    <Flex  justify="center" direction="column">
                                                        <Image style={{width:60,height:60}} source={{uri:temp_teams[item.teamID1].logo}}/>
                                                        <Text>{temp_teams[item.teamID1].name}</Text>
                                                    </Flex>
                                                    <Flex.Item>
                                                        <Flex justify="center" direction="column">
                                                            <Text>{"三局两胜"}</Text>
                                                            <WhiteSpace/>
                                                            <Button onClick={()=>{
                                                                this.props.dispatch(NavigationActions.navigate({
                                                                    routeName:'MatchGameList',
                                                                    params: {schedule_uid:item.schedule_uid,matchid:this.state.showid},
                                                                }))
                                                            }
                                                            } size="small" type="ghost">系列赛</Button>
                                                        </Flex>
                                                    </Flex.Item>
                                                    <Flex  justify="center" direction="column">
                                                        <Image style={{width:60,height:60}} source={{uri:temp_teams[item.teamID2].logo}}/>
                                                        <Text>{temp_teams[item.teamID2].name}</Text>
                                                    </Flex>
                                                </Flex>
                                            </List.Item>
                                        })
                                    }
                                    </List>
                                </View>
                            </Accordion.Panel>
                        </Accordion>

                        <WhiteSpace/>
                        <WingBlank>
                            <Flex>
                                <Flex.Item><Button
                                    onClick={()=>{
                                        this.props.dispatch(NavigationActions.navigate({
                                            routeName:'CreateTempTeam',
                                            params: {showid:this.state.showid,matchinfo:this.state.matchinfo,players:this.state.players},
                                        }))
                                    }}
                                    style={{marginLeft:5}} type="primary">随机组队</Button></Flex.Item>
                            </Flex>
                        </WingBlank>
                </View>:<ActivityIndicator
                        text="Loading..."
                    />
                }
                </ScrollView>
            </View>
        )
    }

}