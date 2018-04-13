import React,{PureComponent} from 'react'
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
    player_flex_item:{
        alignItems:"center"
    },
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
    player_image:{
        width:44,height:54,borderRadius:10,borderColor:'blue',borderWidth:1
    },
})

export default class BasketMatch_PlayerInfo extends PureComponent{

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

    dataStatistics = (id,nickname,teamindex)=>{
        const BUTTONS = ['1分', '2分', '3分','篮板','助攻','抢断','失误','犯规',"盖帽"];
        ActionSheet.showActionSheetWithOptions({
                options: BUTTONS,
                cancelButtonIndex: BUTTONS.length - 1,
                destructiveButtonIndex: BUTTONS.length - 2,
                message: nickname+'的技术统计',
                maskClosable: true
            },
            (buttonIndex) => {
                var type = "";
                var value = 0;
                if(buttonIndex == 0){
                    type = "point";
                    value = 1;
                }else if(buttonIndex == 1){
                    type = "point";
                    value = 2;
                }else if(buttonIndex == 2){
                    type = "point"
                    value = 3;
                }else if(buttonIndex == 3){
                    type = "rebound"
                    value = 1;
                }else if(buttonIndex == 4){
                    type = "assists"
                    value = 1;
                }else if(buttonIndex == 5){
                    type = "steals"
                    value = 1;
                }else if(buttonIndex == 6){
                    type = "fault"
                    value = 1;
                }else if(buttonIndex == 7){
                    type = "foul"
                    value = 1;
                }else if(buttonIndex == 8){
                    type = "block"
                    value = 1;
                }
                this.props.dispatch({type:"CurrentAdminMatchModel/addDataStatistics",payload:{id,type,value,teamindex}})
            })
    }

    render(){
        const {playerStatistics,playerInfo,teamindex} = this.props;
        return (
            <Flex.Item style={styles.player_flex_item}>
                <Flex>
                    <Text style={styles.playerdata}>{this.obj2number(playerStatistics,"point")}</Text>
                    <Text style={styles.playerdata}>{this.obj2number(playerStatistics,"rebound")}</Text>
                    <Text style={styles.playerdata}>{this.obj2number(playerStatistics,"assists")}</Text>
                </Flex>
                <WhiteSpace/>
                <Badge text={this.obj2number(playerStatistics,"foul")}>
                    <TouchableHighlight onPress={()=>{this.dataStatistics(playerInfo.id,playerInfo.nickname,teamindex)}}>
                        <Image style={styles.player_image} source={{uri:playerInfo.image}}/>
                    </TouchableHighlight>
                </Badge>
                <Flex>
                    <Text style={styles.playerdata}>{this.obj2number(playerStatistics,"block")}</Text>
                    <Text style={styles.playerdata}>{this.obj2number(playerStatistics,"steals")}</Text>
                    <Text style={styles.playerdata}>{this.obj2number(playerStatistics,"fault")}</Text>
                </Flex>
                <WhiteSpace/>
                <Button type="ghost"size="small" onClick={()=>{
                    this.props.navigation.navigate("ShootPoint",{playerInfo,teamindex})
                }}>投篮点</Button>
            </Flex.Item>
        )
    }
}