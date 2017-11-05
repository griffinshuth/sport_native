import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    TextInput,
    Platform,
    ScrollView
} from 'react-native'
import {
    WhiteSpace,
    Button,
    Toast,
    Card,
    WingBlank,
    List,
    InputItem,
    SearchBar,
    Popover,
    Modal
} from 'antd-mobile'

import {NativeModules} from 'react-native'
var ChatModule = NativeModules.ChatModule;

import {
    NavigationActions,
    StackNavigator,
    addNavigationHelpers
} from 'react-navigation'
import {connect} from 'dva'
import TabBarTest from '../test/TabBarTest'
import ToolBar from '../../Components/ToolBar'

const createAction = type => payload => ({type,payload})

const styles = StyleSheet.create({
    container:{
        flex:1,
        //alignItems:'center',
        //justifyContent:'center'
    },
    icon:{
        width:32,
        height:32
    },
})

let overlay = [1, 2, 3].map((i, index) => (
    <Popover.Item key={index} value={`option ${i}`}><Text>option {i}</Text></Popover.Item>
));
overlay = overlay.concat([
    <Popover.Item key="4" value="disabled" disabled><Text style={{ color: '#ddd' }}>disabled opt</Text></Popover.Item>,
    <Popover.Item key="6" value="button ct" style={{ backgroundColor: '#efeff4' }}><Text>关闭</Text></Popover.Item>,
]);

@connect(({appNS,user})=>({appNS,user}))
class Main extends Component{
    static navigationOptions = {
        title:"首页",
        headerRight: <Image source={require('../../assets/images/sao.png')} style={{width:28,height:28,marginRight:10}}/>,
        headerStyle:{backgroundColor:"#0099FF"}
    }
    constructor(props){
        super(props);
        this.state = {
            chatlogin:false,
            username:'test',
            password:'123',
            friendname:'',
            modal1:false,
        }
        //this.easeChatRegister = this.easeChatRegister.bind(this);
    }
    gotoCount = ()=>{
        //this.props.navigation.navigate('Count')
        this.props.dispatch(NavigationActions.navigate({routeName:'Count'}))
    }
    gotoBTDiscover = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BTDiscover'}))
    }
    gotoBle = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BLEPage'}))
    }
    gotoCrossPlatformP2P=()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'BluetoothCrossPlatform'}))
    }
    componentDidMount(){
        this.props.dispatch(createAction('user/getUserInfo')({token:this.props.appNS.token}))
    }

    easeChatRegister = async () => {
        try{
            var result = await ChatModule.register(this.state.username,this.state.password,"")
            Toast.info(result);
        }catch(e){
            console.error(e);
        }
    }

    easeChatLogin = async () => {
        try{
            var result = await ChatModule.login(this.state.username,this.state.password);
            this.setState({chatlogin:true});
        }catch(e){
            console.error(e);
        }
    }

    easeChatLogout = async() => {
        try{
            var result = await ChatModule.logout();
            this.setState({chatlogin:false})
        }catch(e){
            console.error(e);
        }
    }

    chatWithFriends = () =>{
        if(this.state.friendname.length > 0)
            ChatModule.chatWithFriends(this.state.friendname)
        else
            Toast.info("好友账号不能为空")
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="首页"
                    headerLeft={<Image source={require('../../assets/images/sao.png')} style={{width:28,height:28}}/>}
                    navigation={this.props.navigation}
                    headerRight={
                            <Image source={require('../../assets/images/sao.png')} style={{width:28,height:28}}/>
                    } />
                <ScrollView style={styles.container}>
                <WhiteSpace/>
                <WingBlank>
                    <View style={{height:100,backgroundColor:'red',transform:[{scale:1}]}}>
                        <Button onClick={()=>this.setState({modal1:true})}>对话框</Button>
                        <Modal
                            title="这是 title"
                            transparent
                            maskClosable={true}
                            visible={this.state.modal1}
                            onClose={()=>this.setState({modal1:false})}
                            footer={[{ text: '确定', onPress: () => {  this.setState({modal1:false}) } }]}
                        >
                            <Text>这是内容...</Text>
                            <Text>这是内容...</Text>
                        </Modal>
                    </View>
                    <Text>即将开始和进行中的比赛，热门推荐，未读消息</Text>
                    <Text>{JSON.stringify(this.props.user)}</Text>
                    <WhiteSpace/>
                    <Button onClick={this.gotoCount}>计数页面</Button>
                    <Button onClick={this.gotoBTDiscover}>蓝牙搜索</Button>
                    <Button onClick={this.gotoBle}>BLE</Button>
                    <Button onClick={this.gotoCrossPlatformP2P}>跨平台P2P</Button>
                </WingBlank>

                <WhiteSpace size="lg"/>
                <WingBlank>
                <Card>
                    <Card.Header
                        title="聊天"
                        thumb="https://www.easemob.com/themes/official_v3/Public/img/logo.png"

                    />
                    <Card.Body style={{backgroundColor:'#ccc'}}>
                        <WingBlank>
                            {
                                this.state.chatlogin?
                                    <List>
                                        <InputItem
                                            labelNumber="5"
                                            value={this.state.friendname}
                                            onChange={value=>this.setState({friendname:value})}
                                        >好友账号：</InputItem>
                                        <Button
                                        onClick={this.chatWithFriends}
                                        >聊天</Button>
                                        <Button
                                        onClick={this.easeChatLogout}
                                        >注销</Button>
                                    </List>
                                    :
                                    <List>
                                    <InputItem
                                        value={this.state.username}
                                        onChange={value=>this.setState({username:value})}
                                    >用户名：</InputItem>
                                    <InputItem
                                        value={this.state.password}
                                        onChange={value=>this.setState({password:value})}
                                    >密码：</InputItem>
                                    <Button
                                    onClick={this.easeChatRegister}
                                    >注册</Button>
                                    <Button
                                    onClick={this.easeChatLogin}
                                    >登陆</Button>
                                </List>
                            }
                        </WingBlank>
                    </Card.Body>
                    <Card.Footer content="" />
                </Card>
                </WingBlank>
            </ScrollView>
            </View>
        )
    }
}

var MainNavigator = StackNavigator(
    {
        Main:{screen:Main},
        TabBarTest:{screen:TabBarTest}
    },
    {
        headerMode:'none'
    }
)

export default class Tab1Page extends Component{
    constructor(props){
        super(props);
        this.state = {
            newinfonum:1
        }
    }
    static navigationOptions = {
        tabBarLabel:'首页',
        tabBarIcon: ({ focused, tintColor }) =>
            <View>
                <Image
                    style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                    source={require('../../assets/images/house.png')}
                />
            </View>
            ,
    }

    render(){
        return (
            <Main navigation={this.props.navigation} />
        )
    }
}

