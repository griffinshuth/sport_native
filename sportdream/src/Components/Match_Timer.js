/*import React from 'react'
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
    Flex,
} from 'antd-mobile'

const styles = StyleSheet.create({
    comment:{
        backgroundColor:'white',borderWidth:1,borderColor:'#ccc',borderRadius:5
    },
    time_font:{
        fontSize:20,fontWeight:"bold"
    },
    player_flex_item:{
        alignItems:"center"
    },
})

const MatchTimer = ({isTimerStart,currentsection,currentsectiontime,currentattacktime,countDown,ballControlChange,reset24,gotoTeamShootPoint}) => {

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

    return (
        <View style={styles.comment}>
            <WhiteSpace/>
            <Flex>
                <Flex.Item><WingBlank><Button onClick={countDown} size="small" type="ghost">{isTimerStart?"停止":"开始"}</Button></WingBlank></Flex.Item>
                <Flex.Item><WingBlank><Button onClick={ballControlChange} size="small" type="ghost">球权转换</Button></WingBlank></Flex.Item>
            </Flex>
            <WhiteSpace/>
            <Flex>
                <Flex.Item style={styles.player_flex_item}><Text style={styles.time_font}>第{currentsection}节</Text></Flex.Item>
                <Flex.Item style={styles.player_flex_item}><Text style={styles.time_font}>{second2time(currentsectiontime)}</Text></Flex.Item>
                <Flex.Item style={styles.player_flex_item}><Text style={styles.time_font}>{currentattacktime}</Text></Flex.Item>
            </Flex>
            <WhiteSpace/>
            <Flex>
                <Flex.Item><WingBlank><Button onClick={reset24} size="small" type="ghost">24秒重置</Button></WingBlank></Flex.Item>
                <Flex.Item><WingBlank><Button onClick={gotoTeamShootPoint} size="small" type="ghost">投篮统计</Button></WingBlank></Flex.Item>
            </Flex>
            <WhiteSpace/>
        </View>
    )
}

export default MatchTimer
*/