import React,{Component} from 'react'
import {
    StyleSheet,
    TouchableOpacity,
    Text,
    View,
    Image,
    ScrollView,
} from 'react-native'

import {connect} from 'dva'
import {
    NavigationActions
} from 'react-navigation'

import {
    WhiteSpace,
    Flex,
    WingBlank,
    Button,
    List,
    InputItem,
    Toast,
    NoticeBar
} from 'antd-mobile'

import FadeInView from '../utils/FadeInView'
const createAction = type => payload => ({type,payload})

@connect(
    ({appNS,temp}) => ({appNS,temp})
)
export default class LoginPage extends Component{
    static navigationOptions = {
        title:'登陆'
    }
    constructor(props){
        super(props);
        this.state = {
            phonenumber:"",
            password:""
        }
    }
    goLogin(payload){
        this.props.dispatch(createAction('appNS/login')(payload));
    }
    render(){
        return (
            <ScrollView contentContainerStyle={styles.container}>
                {this.props.temp.loginError != 0?<NoticeBar mode="closable" icon={null}>账号或密码错误</NoticeBar>:null}
                <WhiteSpace size="xl"/>
                <FadeInView>
                    <Image style={styles.logo} source={require('../assets/images/sports.png')} />
                </FadeInView>
                <WhiteSpace size="xl"/>
                <List style={{width:'100%'}} renderHeader={() => '登陆'}>
                    <InputItem
                        value={this.state.phonenumber}
                        type="phone"
                        placeholder="手机号码"
                        onChange={(value)=>this.setState({phonenumber:value})}
                    >手机号码</InputItem>
                    <InputItem
                        value={this.state.password}
                        type="password"
                        placeholder="****"
                        onChange={(value)=>this.setState({password:value})}
                    >密码</InputItem>
                </List>
                <WhiteSpace/>
                <Flex direction="row">
                    <Flex.Item>
                        <Button loading={this.props.temp.loginLoading} onClick={()=>this.goLogin({phonenumber:this.state.phonenumber.replace(/\s/g,''),password:this.state.password})}>登陆</Button>
                    </Flex.Item>
                    <Flex.Item>
                        <Button onClick={()=>this.props.navigation.navigate('Register')}>注册</Button>
                    </Flex.Item>
                </Flex>
                <WhiteSpace size="xl"/>
                <View><Text>第三方登陆</Text></View>
                <WhiteSpace/>
                <Flex direction="row">
                    <Image style={styles.thirdlogin} source={require('../assets/images/weixin.png')} />
                    <Image style={styles.thirdlogin} source={require('../assets/images/qq.png')} />
                    <Image style={styles.thirdlogin} source={require('../assets/images/facebook.png')} />
                    <Image style={styles.thirdlogin} source={require('../assets/images/twitter.png')} />
                </Flex>
            </ScrollView>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        alignItems:'center',
        justifyContent:'flex-start'
    },
    loginButton:{
        backgroundColor:'green',
        alignItems:'center',
        justifyContent:'center',
        height:30,
        width:100,
        borderRadius:10
    },
    loginLabel:{
        fontSize:16,
        color:'white'
    },
    center:{
        flex:1,
        alignItems:'center',
        justifyContent:'center'
    },
    logo:{
        width:64,
        height:64
    },
    thirdlogin:{
        width:32,
        height:32,
        marginRight:10
    }
})