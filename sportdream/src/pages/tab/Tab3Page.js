import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    TouchableHighlight,
    NativeModules,
    ScrollView,
    RefreshControl,
    FlatList
} from 'react-native'
import {
    Button,
    Modal,
    List,
    Tag,
    WingBlank,
    Toast,
    Badge,
    Tabs
} from 'antd-mobile'

import {NavigationActions} from 'react-navigation'
import {connect} from 'dva'
import ToolBar from '../../Components/ToolBar'
import MatchItem from '../../Components/MatchItem'
import {get,post} from '../../fetch'
import eventtype from '../../utils/EventType'
import emitter from '../../utils/SingleEventEmitter'

const tabs = [
    { title: "创建" },
    { title: "参与" },
    { title: "附近" },
    {title:"热门"}
];

@connect(({appNS,user})=>({appNS,user}))
export default class Tab3Page extends Component{
    constructor(props){
        super(props);
        this.state = {

        }
    }

    componentDidMount(){

    }



    render(){
        return (
            <View style={styles.container}>
                <ToolBar title="体能" navigation={this.props.navigation}/>
                <View>

                </View>
            </View>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1
    },
    icon:{
        width:32,
        height:32
    }
})