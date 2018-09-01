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
    static navigationOptions = {
        tabBarLabel:'比赛',
        tabBarIcon: ({ focused, tintColor }) =>
            <Image
                style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                source={require('../../assets/images/match.png')}
            />,
    }

    constructor(props){
        super(props);
        this.state = {
            isRefreshing: false,
            matches:[]
        }
    }

    componentDidMount(){
        this.matchload();
        emitter.addListener(eventtype.ReloadCreatedMatch,(msg)=>{
            this.matchload();
        })
    }

    matchload = async()=>{
        this.setState({isRefreshing: true});
        var result = await post('/getStreetMatchByUserUid',{token:this.props.appNS.token})
        this.setState({isRefreshing: false});
        if(!result.error){
            this.setState({matches:result.matches});
        }else{
            this.props.dispatch({type:"appNS/loginout"})
        }
    }

    deleteMatch = async(showid)=>{
        var result = await post('/removeMatchByShowId',
            {
                token:this.props.appNS.token,
                showid:showid
            })
        this.matchload();
    }

    _onRefresh = ()=>{
        this.matchload();
    }

    render(){
        return (
            <View style={styles.container}>
                <ToolBar title="比赛" navigation={this.props.navigation}
                         headerRight={
                                 <TouchableHighlight onPress={() => {
                                     Modal.operation([
                                         {text:'野球赛',onPress:()=>{
                                             this.props.dispatch(NavigationActions.navigate({routeName:'CreateStreetMatch'}))
                                         }},
                                         {text:'热身赛'}
                                     ])
                                 }}>
                                     <Image source={require('../../assets/images/createstreetmatch.png')} style={{width:28,height:28}}/>
                                 </TouchableHighlight>
                         }
                />
                <Tabs swipeable={false} tabs={tabs}
                      initialPage={0}>

                    <View style={{flex:1}}>
                        <ScrollView
                            automaticallyAdjustContentInsets={false}
                            style={{flex:1}}
                            refreshControl={
                                <RefreshControl
                                    refreshing={this.state.isRefreshing}
                                    onRefresh={this._onRefresh}
                                    tintColor="#ff0000"
                                    title="加载中..."
                                    titleColor="#00ff00"
                                    colors={['#ff0000', '#00ff00', '#0000ff']}
                                    progressBackgroundColor="#ffff00"
                                />
                            }
                        >
                            {this.state.matches.length == 0?<Button onClick={() => {
                                Modal.operation([
                                    {text:'野球赛',onPress:()=>{
                                        this.props.dispatch(NavigationActions.navigate({routeName:'CreateStreetMatch'}))
                                    }},
                                    {text:'热身赛'}
                                ])
                            }}>创建比赛</Button>:<List renderHeader={()=>'创建的比赛列表'}>
                                {
                                    this.state.matches.map((item,index) => {
                                        return <List.Item
                                            key={item.match_showid}
                                            multipleLine
                                            arrow="horizontal"
                                            onClick={() => {
                                                this.props.dispatch(NavigationActions.navigate({
                                                    routeName:'MatchDetail',
                                                    params: {showid:item.match_showid},
                                                }))
                                            }}
                                            style={{height:80}}>
                                            <MatchItem
                                                key={item.match_showid}
                                                match_showid={item.match_showid}
                                                create_useruid={item.create_useruid}
                                                match_type={item.match_type}
                                                match_state={item.match_state}
                                                sport_type={item.sport_type}
                                                city_name={item.city_name}
                                                createtime={item.createtime}
                                                headerimage={this.props.user.headerimage}
                                                deleteMatch={this.deleteMatch}
                                            />
                                        </List.Item>
                                    })
                                }
                            </List>}
                        </ScrollView>
                    </View>


                    <View style={{flex:1, alignItems: 'center', justifyContent: 'center', height: 400 }}>
                        <Text>选项卡二内容</Text>
                    </View>


                    <View style={{flex:1, alignItems: 'center', justifyContent: 'center', height: 400 }}>
                        <Text>选项卡三内容</Text>
                    </View>

                </Tabs>

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