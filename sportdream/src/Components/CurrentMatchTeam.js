import React from 'react'
import PropTypes from 'prop-types'
import {
    View,
    Text,
    Image,
    TouchableHighlight,
    ScrollView,
    StyleSheet,
} from 'react-native'

import {
    Button,
    WhiteSpace,
    WingBlank,
    Toast,
    Flex,
    Card,
    ActionSheet,
    List,
    Modal,
    ActivityIndicator,
    Badge,
    Slider
} from 'antd-mobile'

const styles = StyleSheet.create({
    playerdata:{
        color:'#ccc',
        fontSize:10,
        lineHeight:16,
        width:16,
        height:16,
        borderWidth:1,
        borderColor:'#eee',
        textAlign:'center',
        borderRadius:8,
    },
    container:{
        flex:1
    },
    teamlogo:{
        width:32,height:32
    },
    teamname:{
        marginLeft:10
    },
    teamstate:{
        marginLeft:10,color:'red',fontWeight:"bold",fontSize:20
    },
    card_background:{
        backgroundColor:'white'
    },
    data_button:{
        marginLeft:5,height:30
    },
    player_flex_item:{
        alignItems:"center"
    },
    player_image:{
        width:44,height:54,borderRadius:10,borderColor:'blue',borderWidth:1
    },
    comment:{
        backgroundColor:'white',borderWidth:1,borderColor:'#ccc',borderRadius:5
    },
    time_font:{
        fontSize:20,fontWeight:"bold"
    }
})

const CurrentMatchTeam = ({teamindex,teaminfo,teamcurrentscore,teamMembers,roomInfo,teamtimeout,addScore,dataStatistics,gotoShootPoint,requestTimeout,gotoTeamsubstitution,isBonus}) => {
    obj2number = (playerdata,type)=>{
        if(!playerdata){
            return 0;
        }
        if(!playerdata[type]){
            return 0;
        }

        var total = 0;
        for(var i=0;i<playerdata[type].length;i++){
            total += playerdata[type][i].number;
        }
        return total;
    }

    return (
        <Card>
            <Card.Header
                title={
                    <Flex>
                        <Image source={{uri:teaminfo.logo}} style={styles.teamlogo} />
                        <Text style={styles.teamname}>{teaminfo.name}</Text>
                        <Text style={styles.teamstate}>{roomInfo.ballowner == 1?"攻":""}</Text>
                    </Flex>
                }
                extra={"得分:"+teamcurrentscore}
            />
            <Card.Body>
                <View style={styles.card_background}>
                    <WhiteSpace/>
                    <Flex justify="center">
                        <Button style={styles.data_button} type="ghost" onClick={()=>{addScore(teamindex,1)}}>1分</Button>
                        <Button style={styles.data_button} type="ghost" onClick={()=>{addScore(teamindex,2)}}>2分</Button>
                        <Button style={styles.data_button} type="ghost" onClick={()=>{addScore(teamindex,3)}}>3分</Button>
                    </Flex>
                    <WhiteSpace/>
                    <Flex>
                        {
                            teamMembers.map((item,index)=>{
                                return <Flex.Item style={styles.player_flex_item} key={item.id}>
                                    <Flex>
                                        <Text style={styles.playerdata}>{obj2number(roomInfo[item.id],"point")}</Text>
                                        <Text style={styles.playerdata}>{obj2number(roomInfo[item.id],"rebound")}</Text>
                                        <Text style={styles.playerdata}>{obj2number(roomInfo[item.id],"assists")}</Text>
                                    </Flex>
                                    <WhiteSpace/>
                                    <Badge text={obj2number(roomInfo[item.id],"foul")}>
                                        <TouchableHighlight onPress={
                                            ()=>{
                                                dataStatistics(item.id,item.nickname,0)
                                            }
                                        }>
                                            <Image style={styles.player_image} source={{uri:item.image}}/>
                                        </TouchableHighlight>
                                    </Badge>
                                    <Flex>
                                        <Text style={styles.playerdata}>{obj2number(roomInfo[item.id],"block")}</Text>
                                        <Text style={styles.playerdata}>{obj2number(roomInfo[item.id],"steals")}</Text>
                                        <Text style={styles.playerdata}>{obj2number(roomInfo[item.id],"fault")}</Text>
                                    </Flex>
                                    <WhiteSpace/>
                                    <Button type="ghost"size="small" onClick={
                                        ()=>{gotoShootPoint(item)}
                                    }>投篮点</Button>
                                </Flex.Item>
                            })
                        }
                    </Flex>
                    <WhiteSpace/>
                    <Flex justify="center">
                        <Button style={styles.data_button} type="ghost" onClick={()=>{requestTimeout(teamindex)}}>暂停</Button>
                        <Button style={styles.data_button} type="ghost" onClick={
                            ()=>{gotoTeamsubstitution(teamindex)}
                        }>换人</Button>
                    </Flex>
                </View>
            </Card.Body>
            <Card.Footer content={"可用暂停："+teamtimeout} extra={isBonus(teamindex)?"BONUS":""} />
        </Card>
    )
}

export default CurrentMatchTeam
