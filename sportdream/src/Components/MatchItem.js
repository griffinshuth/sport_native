import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    TouchableHighlight,
} from 'react-native'
import {
    Button,
    Modal,
    List,
    Tag,
    WingBlank
} from 'antd-mobile'
import type2text from '../utils/Type2Text'


export default class App extends React.Component{
    render(){
        if(this.props.sport_type == 1){
            var sport_img = require('../assets/images/basketball.png')
        }else if(this.props.sport_type){
            var sport_img = require('../assets/images/football.png')
        }

        var matchstate = type2text.getMatchState(this.props.match_state)
         return <View style={{flex:1,flexDirection:'row',alignItems:'center'}}>
            <View>
                <Image source={sport_img} style={{width:44,height:44}}/>
            </View>
            <View style={{marginLeft:10}}>
                <View style={{
                    flex:1,
                    flexDirection:'row',
                    alignItems:'center',
                }}>
                    <Tag selected><Text
                        style={{fontStyle:'italic',fontSize:18,fontWeight:'bold'}}
                    >{this.props.match_showid}</Text></Tag>
                    {this.props.headerimage?<Image source={{uri:this.props.headerimage}}
                                                        style={{borderWidth:2,borderColor:"#ccc",width:32,height:32,borderRadius:16,marginLeft:10}}/>:null}
                    <WingBlank size="sm">
                        <Button size="small"
                                type="primary"
                                style={{width:50}}
                                onClick={() => Modal.alert('删除', '是否删除比赛', [
                                    { text: '取消', onPress: () => console.log('cancel') },
                                    { text: '删除', onPress: () => this.props.deleteMatch(this.props.match_showid) },
                                ])}>删除</Button>
                    </WingBlank>
                </View>
                <View style={{flex:1,flexDirection:'row',alignItems:'flex-end'}}>
                    <WingBlank size="sm"><Tag small>{matchstate}</Tag></WingBlank>
                    <WingBlank size="sm"><Tag small>{this.props.city_name}</Tag></WingBlank>
                    <WingBlank size="sm"><Tag small>{type2text.getMatchType(this.props.match_type)}</Tag></WingBlank>
                </View>
            </View>
        </View>
    }
}