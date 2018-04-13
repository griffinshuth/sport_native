import React,{PureComponent} from 'react'
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
    comment:{
        backgroundColor:'white',borderWidth:1,borderColor:'#ccc',borderRadius:5
    },
    time_font:{
        fontSize:20,fontWeight:"bold"
    }
})

import BasketMatch_PlayerInfo from "./BasketMatch_PlayerInfo"

class CurrentBasketMatchTeam extends PureComponent
{
    addScore = (teamIndex,score)=>{
        this.props.dispatch({type:"CurrentAdminMatchModel/addScore",payload:{teamIndex,score}})
    }
    requestTimeout = (teamIndex)=>{
        this.props.dispatch({type:"CurrentAdminMatchModel/requestTimeout",payload:{teamIndex}})
    }
    render(){
        const {teamindex,teaminfo,teamcurrentscore,teamMembers,membersOffCourt,ballowner,teamtimeout,teamdataStatistics} = this.props;
        return (<Card>
            <Card.Header
                title={
                    <Flex>
                        <Image source={{uri:teaminfo.logo}} style={styles.teamlogo} />
                        <Text style={styles.teamname}>{teaminfo.name}</Text>
                        <Text style={styles.teamstate}>{ballowner == (teamindex+1)?"攻":""}</Text>
                    </Flex>
                }
                extra={"得分:"+teamcurrentscore}
            />
            <Card.Body>
                <View style={styles.card_background}>
                    <WhiteSpace/>
                    <Flex justify="center">
                        <Button style={styles.data_button} type="ghost" onClick={()=>{this.addScore(teamindex,1)}}>1分</Button>
                        <Button style={styles.data_button} type="ghost" onClick={()=>{this.addScore(teamindex,2)}}>2分</Button>
                        <Button style={styles.data_button} type="ghost" onClick={()=>{this.addScore(teamindex,3)}}>3分</Button>
                    </Flex>
                    <WhiteSpace/>
                    <Flex>
                        {
                            teamMembers.map((item,index)=>{
                                return <BasketMatch_PlayerInfo
                                    key={item.id}
                                    dispatch={this.props.dispatch}
                                    playerStatistics={teamdataStatistics[item.id]}
                                    playerInfo={item}
                                    teamindex={teamindex}
                                    navigation={this.props.navigation}
                                />
                            })
                        }
                    </Flex>
                    <WhiteSpace/>
                    <Flex justify="center">
                        <Button style={styles.data_button} type="ghost" onClick={()=>{this.requestTimeout(teamindex)}}>暂停</Button>
                        <Button style={styles.data_button} type="ghost" onClick={()=>{
                            if(membersOffCourt.length == 0){
                                Toast.info("无人可换",1)
                                return;
                            }
                            this.props.navigation.navigate("substitution",{
                                teamIndex:teamindex,
                            })
                        }}>换人</Button>
                    </Flex>
                </View>
            </Card.Body>
            <Card.Footer content={"可用暂停："+teamtimeout} extra={""} />
        </Card>)
    }
}

export default CurrentBasketMatchTeam