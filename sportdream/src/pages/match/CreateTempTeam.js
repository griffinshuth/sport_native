import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    Image,
    ScrollView
} from 'react-native'
import {
    List,
    Flex,
    Steps,
    WhiteSpace,
    Card,
    WingBlank,
    Toast,
    Modal,
    Button,
    Picker
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {post} from '../../fetch'
import {NavigationActions} from 'react-navigation'

const leagueType = [

    {label:'车轮战',value:"1"},
    {label:'杯赛',value:"2"},
    {label:'循环赛',value:"3"},
    {label:'循环+杯赛',value:"4"},
    {label:'小组+杯赛',value:'5'},
    {label:'自定义赛程',value:'6'}

]

@connect()
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            temp_teams:[], //{name:"",logo:"",members:[]}  members:{id:-1,icon:"",text:""}
            startupnumber:["1"],
            schedule:[],  //{team1:-1,team2:-1,state:"未开赛",room:{},matchresult:{}}
        }
    }

    createTempTeams = ()=>{
        var startup = this.props.navigation.state.params.matchinfo.detail.match_rule.startup_num;
        var players = this.props.navigation.state.params.players;
        if(players.length < startup*2){
            Toast.info("球员不足组成两队",1)
            return;
        }
        var team_num = Math.floor(players.length/startup)
        //初始化球队
        var temp_teams = [];
        for(var i=0;i<team_num;i++){
            var team = {name:"",logo:"",members:[]};
            temp_teams.push(team);
        }

        var player_arr = [];
        for(var i=0;i<players.length;i++){
            player_arr[i] = players[i];
        }
        player_arr.sort(function (a,b) {
            return Math.random()>0.5?-1:1;
        })
        for(var i=0;i<player_arr.length;i++){
            var tindex = i%team_num;
            temp_teams[tindex].members.push(player_arr[i]);
        }
        this.setState({temp_teams:temp_teams})
    }

    createTeam = async(index)=>{
        //Toast.info(index,1);
        Modal.prompt('队名', '输入队伍名称', [
            { text: 'Cancel' },
            { text: 'Submit', onPress:async(value)=>{
                if(value.length < 2){
                    return;
                }
                var teams = this.state.temp_teams;
                var result = await post("/createTeamLogo",{teamname:value});
                teams[index].name = value;
                teams[index].logo = result.base64;
                this.setState({temp_teams:teams})
            }},
        ])
    }

    createInitSchedule = ()=>{
        //判断球队是否已经生成
        if(this.state.temp_teams.length <2){
            Toast.info("请先生成球队",1);
            return;
        }
        //判断是否已经生成球队名称和logo
        for(var i=0;i<this.state.temp_teams.length;i++){
            if(!this.state.temp_teams[i].name){
                Toast.info("请先设置球队名称和logo",1)
                return;
            }
        }

        //根据赛制生成赛程
        var schedule = [];
        var teamcount = this.state.temp_teams.length;
        for(var i=0;i<teamcount;i++){
            for(var j=0;j<teamcount;j++){
                if(i != j){
                    schedule.push({team1:i,team2:j,state:"未开赛",room:{},matchresult:{}})
                }
            }
        }

        this.setState({schedule:schedule})

    }

    componentDidMount(){

    }

    render(){
        var showid = this.props.navigation.state.params.showid;
        return (
            <View style={{flex:1}}>
                <ToolBar title="球队创建" navigation={this.props.navigation} />
                <ScrollView style={{flex:1}}>
                <List>
                    <List.Item>
                        <Text>比赛ID：{showid}</Text>
                    </List.Item>
                </List>
                <WhiteSpace/>
                <Flex justify="start" align="start">
                    <Steps current={0} direction="horizontal">
                        <Steps.Step key={1} status="process" title={"进行中"} description={null}></Steps.Step>
                        <Steps.Step key={2} status="wait" title={"等待"} description={null}></Steps.Step>
                        <Steps.Step key={3} status="wait" title={"等待"} description={null}></Steps.Step>
                    </Steps>
                    <Flex direction="column" style={{width:230}}>
                        <Flex.Item><Button onClick={this.createTempTeams} size="small" type="ghost">创建球队</Button></Flex.Item>
                        <Flex.Item>
                            <List style={{width:230}}>
                                <Picker
                                    data={leagueType}
                                    title="选择赛制"
                                    cols={1}
                                    extra="请选择(可选)"
                                    value={this.state.startupnumber}
                                    onChange={v=>{this.setState({startupnumber:v})}}
                                >
                                    <List.Item arrow="horizontal">赛制</List.Item>
                                </Picker>
                            </List>
                        </Flex.Item>
                        <Flex.Item><Button onClick={this.createInitSchedule} size="small" type="ghost">生成赛程</Button></Flex.Item>
                    </Flex>
                </Flex>
                <List renderHeader={()=>"球队"}>
                    <WingBlank size="lg">
                        {
                            this.state.temp_teams.map((item,index) => {
                                return (
                                    <View key={index}>
                                        <WhiteSpace size="lg" />
                                        <Card>
                                            <Card.Header
                                                title={
                                                    <Flex>
                                                        {this.state.temp_teams[index].logo?<Image source={{uri:this.state.temp_teams[index].logo}} style={{width:60,height:60}} />
                                                            :<Button onClick={()=>{this.createTeam(index)}} size="small" type="ghost">生成队名</Button>}
                                                        {this.state.temp_teams[index].name?<Text style={{marginLeft:10}}>{this.state.temp_teams[index].name}</Text>:null}
                                                    </Flex>
                                                }
                                                extra={"战绩"}
                                            />
                                            <Card.Body>
                                                <Flex justify="center" wrap="wrap">
                                                    {
                                                        item.members.map(function (player,playerindex) {
                                                            return (
                                                                <View style={{width:65,alignItems:'center'}} key={playerindex}>
                                                                    <Image source={{uri:player.icon}}
                                                                                                  resizeMode="stretch"
                                                                                                  style={{
                                                                                                      width:44,
                                                                                                      height:60
                                                                                                  }} />
                                                                    <Text>{player.text}</Text>
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
                </List>
                <List renderHeader={()=>"赛程"}>
                    {
                        this.state.schedule.map((item,index)=>{
                            return <List.Item key={index}>
                                <Flex>
                                    <Flex  justify="center" direction="column">
                                        <Image style={{width:60,height:60}} source={{uri:this.state.temp_teams[item.team1].logo}}/>
                                        <Text>{this.state.temp_teams[item.team1].name}</Text>
                                    </Flex>
                                    <Flex.Item>
                                        <Flex justify="center" direction="column">
                                            <Text>{item.state}</Text>
                                            <WhiteSpace/>
                                            <Button onClick={
                                                ()=>{
                                                    this.props.dispatch(NavigationActions.navigate({
                                                        routeName:'match_admin',
                                                        params: {team1:item.team1,team2:item.team2,temp_teams:this.state.temp_teams},
                                                    }))
                                                }
                                            } size="small" type="ghost">技术统计</Button>
                                            <WhiteSpace/>
                                            <Button onClick={()=>{
                                                this.props.dispatch(NavigationActions.navigate({
                                                    routeName:'match_watch',
                                                    params: {team1:item.team1,team2:item.team2,temp_teams:this.state.temp_teams},
                                                }))
                                                }
                                            } size="small" type="ghost">观看</Button>
                                        </Flex>
                                    </Flex.Item>
                                    <Flex  justify="center" direction="column">
                                        <Image style={{width:60,height:60}} source={{uri:this.state.temp_teams[item.team2].logo}}/>
                                        <Text>{this.state.temp_teams[item.team2].name}</Text>
                                    </Flex>
                                </Flex>
                            </List.Item>
                        })
                    }
                </List>
                </ScrollView>
            </View>
        )
    }
}