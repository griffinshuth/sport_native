import React,{PureComponent} from 'react'
import {
    View,
    Text,
    Image,
    TouchableHighlight,
    ScrollView,
    StyleSheet,
} from 'react-native'

const styles = StyleSheet.create({
    container:{
        flexDirection:'row',
    },
    time_font:{
        fontSize:20,fontWeight:"bold"
    },
    item:{
        flex:1,
        alignItems:'center',
        justifyContent:'center'
    }
})

export default class BasketMatch_SectionTime extends PureComponent{
    second2time = (second)=>{
        var m_text = "";
        var s_text = "";
        var m = Math.floor(second/60);
        if(m == 0){
            var result = second;
            if(m == 0 && second == 0){
                result = "结束"
            }
            return result;
        }else{
            var s = second%60;
            m_text = m;
            if(s<10){
                s_text = "0"+s;
            }else{
                s_text = s;
            }
            var result = m_text+":"+s_text;
            return result;
        }
    }

    render(){
        const {currentsectiontime,currentsection,currentattacktime} = this.props;

        return (
            <View style={styles.container}>
                <View style={styles.item}><Text style={styles.time_font}>{this.second2time(currentsectiontime)}</Text></View>
                <View style={styles.item}><Text style={styles.time_font}>第{currentsection}节</Text></View>
                    <View style={styles.item}><Text style={styles.time_font}>{currentattacktime}</Text></View>
            </View>
        )
    }
}