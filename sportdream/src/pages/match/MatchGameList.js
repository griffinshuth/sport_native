import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    Image
} from 'react-native'
import {
    Button,
    List,
    WingBlank,
    WhiteSpace,
    ActivityIndicator,
    Toast,
    Flex
} from 'antd-mobile'

import ToolBar from '../../Components/ToolBar'
import {get, post, promisePost} from '../../fetch'
import {NavigationActions} from 'react-navigation'

@connect()
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            team1:null,
            team2:null,
            games:null,
            loading:true
        }
    }

    gamesLoad = async()=>{
        var {schedule_uid,matchid} = this.props.navigation.state.params;
        var result = await post("/getGameListOfScheduleId",{scheduleid:schedule_uid,matchid:matchid});
        if(result.error){
            Toast.info(errorinfo);
        }else{
            this.setState({
                team1:result.team1,
                team2:result.team2,
                games:result.games,
                loading:false
            })
        }
    }

    componentDidMount(){
        this.gamesLoad();
    }

    render(){
        return (
            <View>
                <ToolBar title="系列赛赛程" navigation={this.props.navigation} />
                {
                    this.state.loading?<ActivityIndicator toast />:<List>
                        {
                            this.state.games.map((item,index)=>{
                                return <List.Item key={index}>
                                    <Flex>
                                        <View style={{alignItems:'center',marginRight:10}}>
                                            <Text>{"9:30"}</Text>
                                        </View>
                                        <View style={{alignItems:'center'}}>
                                            <Image style={{width:60,height:60}} source={{uri:this.state.team1.logo}}/>
                                            <Text>{this.state.team1.name}</Text>
                                        </View>
                                        <Flex.Item style={{alignItems:'center'}}>
                                            <View style={{alignItems:'center'}}>
                                                <Text>第{index+1}局({item.game_uid})</Text>
                                                <WhiteSpace/>
                                                <Button onClick={
                                                    ()=>{
                                                        this.props.dispatch(NavigationActions.navigate({
                                                            routeName:'match_admin',
                                                            params: {
                                                                team1:this.state.team1,
                                                                team2:this.state.team2,
                                                                game_uid:item.game_uid,
                                                                room_uid:item.room_uid
                                                            },
                                                        }))
                                                    }
                                                } size="small" type="ghost">技术统计</Button>
                                                <WhiteSpace/>
                                                <Button onClick={()=>{
                                                    this.props.dispatch(NavigationActions.navigate({
                                                        routeName:'match_watch',
                                                        params: {
                                                            team1:this.state.team1,
                                                            team2:this.state.team2,
                                                            game_uid:item.game_uid,
                                                            room_uid:item.room_uid
                                                        },
                                                    }))
                                                }
                                                } size="small" type="ghost">观看</Button>
                                                <WhiteSpace/>
                                                <Button onClick={()=>{
                                                    this.props.dispatch(NavigationActions.navigate({
                                                        routeName:'Scoreboard',
                                                        params: {
                                                            game_uid:item.game_uid,
                                                            room_uid:item.room_uid
                                                        },
                                                    }))
                                                }
                                                } size="small" type="ghost">记分牌</Button>
                                            </View>
                                        </Flex.Item>
                                        <View style={{alignItems:'center'}}>
                                            <Image style={{width:60,height:60}} source={{uri:this.state.team2.logo}}/>
                                            <Text>{this.state.team2.name}</Text>
                                        </View>
                                        <View style={{alignItems:'center',marginLeft:10}}>
                                            <Text>{"第一节"}</Text>
                                            <Text>{"11:28"}</Text>
                                        </View>
                                    </Flex>
                                </List.Item>
                            })
                        }
                    </List>
                }
            </View>
        )
    }
}