import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Text,
    Animated,
    TouchableOpacity,
    ScrollView,
    Image,
    PanResponder,
    Platform,
    NativeModules,
    Alert,
    TextInput
} from 'react-native'

import {
    Button,
    Toast,
    Flex,
    List,
    InputItem,
    WhiteSpace,
    WingBlank,
    Picker,
    ImagePicker
} from 'antd-mobile'

import {get,post} from '../fetch'


export default class RegisterPage extends Component{
    constructor(props){
        super(props);
        this.state = {
            smscodeinfo:'获得验证码',
            phoneHasError:false,
            smscodeError:false,
            passwordError:false,
            nicknameError:false,
            smsbuttondisabled:false,
            phoneValue:'',
            smscode:'',
            password:'',
            confirmPassword:'',
            nickname:'',
            sex:['man'],
            images:[]
        }
    }
    onPhoneErrorClick=()=>{
        if(this.state.phoneHasError){
            Toast.info("输入11位数字")
        }
    }

    onSmscodeErrorClick = ()=>{
        if(this.state.smscodeError){
            Toast.info("验证码错误")
        }
    }

    onPasswordError = ()=>{
        if(this.state.passwordError){
            Toast.info("密码不少于8位",1)
        }
    }

    onPhoneChange = (value)=>{
        if(value.replace(/\s/g,'').length!=11){
            this.setState({
                phoneHasError:true,
            })
        }else{
            this.setState({
                phoneHasError:false
            })
        }
        this.setState({
            phoneValue:value
        })
    }

    PassWordChange = (value)=>{
        this.setState({
            password:value
        })
    }

    onImageChange = (files,type,index)=>{
        this.setState({images:files})
    }

    onRegister = async()=>{
        var {phoneValue,smscode,password,confirmPassword,nickname,sex} = this.state;
        phoneValue = phoneValue.replace(/\s/g,'');
        try{
            var result =  await post('/register',{phoneValue,smscode,password,confirmPassword,nickname,sex});
            if(result.error){
                Toast.info(result.error);
            }else{
                Toast.info("恭喜注册成功，请返回登录页面进行登录")
            }
        }catch(e){
            Toast.info("无法连接到服务器")
        }
    }

    verifySmsCode = async()=>{
        try{
            var result =  await get('/getSmsCode',{phonenumber:this.state.phoneValue.replace(/\s/g,'')});
            if(result.isEmpty){
                Toast.info("还没有生成验证码，请先获得验证码")
            }else{
                if(result.code != this.state.smscode){
                    this.setState({smscodeError:true});
                }
            }
        }catch(e){
            Toast.info("无法连接到服务器")
        }
    }

    onSendSMSCode = async()=>{
        var phonenumber = this.state.phoneValue.replace(/\s/g,'');
        if(phonenumber.length != 11){
            Toast.info("手机号码格式错误",1);
            return;
        }
        var result =  await post('/sendSmsCode',{phonenumber:phonenumber});
        if(result.resp.respCode == "000000"){
            var t = 60;
            this.setState({smscodeinfo:t+"秒后可以重发"})
            this.setState({smsbuttondisabled:true})

            var timehander = setInterval(()=>{
                t = t-1;
                this.setState({smscodeinfo:t+"秒后可以重发"})
                if(t==0){
                    clearInterval(timehander);
                    this.setState({smscodeinfo:'获得验证码'})
                    this.setState({smsbuttondisabled:false})
                }
            },1000)
        }else{
            Toast.info("发生短信失败！！！")
        }
    }

    checkNickname = async()=>{
        var result =  await get('/isNicknameExist',{nickname:this.state.nickname});
        if(result.exist){
            Toast.info("昵称已经存在")
        }else{
            Toast.info("可以使用")
        }
    }

    render(){
        return (
            <ScrollView style={styles.container}>
                <List renderHeader={()=>'注册'}>
                    <InputItem
                    type="phone"
                    placeholder="输入电话号码"
                    error={this.state.phoneHasError}
                    onErrorClick={this.onPhoneErrorClick}
                    onChange={this.onPhoneChange}
                    value={this.state.phoneValue}
                    clear
                    autoFocus
                    returnKeyType="next"
                    >手机号码</InputItem>
                    <List.Item>
                        <Flex>
                            <Flex.Item>
                                <InputItem
                                    placeholder="输入验证码"
                                    returnKeyType="next"
                                    value={this.state.smscode}
                                    error={this.state.smscodeError}
                                    onErrorClick={this.onSmscodeErrorClick}
                                    onBlur={this.verifySmsCode}
                                    onFocus={()=>this.setState({smscodeError:false})}
                                    onChange={(value)=>this.setState({smscode:value})}
                                ></InputItem>
                            </Flex.Item>
                            <Flex.Item>
                                <Button disabled={this.state.smsbuttondisabled} onClick={this.onSendSMSCode}>{this.state.smscodeinfo}</Button>
                            </Flex.Item>
                        </Flex>

                    </List.Item>
                    <InputItem
                    type="password"
                    placeholder="不少于8位的数字或字母"
                    clear
                    value={this.state.password}
                    error={this.state.passwordError}
                    onBlur={()=>this.setState({passwordError:this.state.password.length < 8})}
                    onFocus={()=>this.setState({passwordError:false})}
                    onErrorClick={this.onPasswordError}
                    onChange={this.PassWordChange}
                    >密码</InputItem>
                    <InputItem
                        type="password"
                        placeholder="****"
                        clear
                        labelNumber="7"
                        value={this.state.confirmPassword}
                        onChange={value=>this.setState({confirmPassword:value})}
                        onBlur={()=>{if(this.state.password != this.state.confirmPassword){Toast.info("密码不一致")}}}
                    >再次输入密码</InputItem>
                    <InputItem
                    placeholder="输入您的昵称"
                    clear
                    value={this.state.nickname}
                    onChange={value=>this.setState({nickname:value})}
                    error={this.state.nicknameError}
                    onErrorClick={()=>{Toast.info("昵称不能为空")}}
                    onBlur={()=>this.setState({nicknameError:this.state.nickname.length == 0})}
                    onFocus={()=>this.setState({nicknameError:false})}
                    extra={<Button onClick={this.checkNickname} type="primary" size="small">是否存在</Button>}
                    >昵称</InputItem>
                    <Picker
                        data={[{label:'男',value:'man'},{label:'女',value:'female'}]}
                        cols={1}
                        value={this.state.sex}
                        onChange={v=>this.setState({sex:v})}
                    >
                        <List.Item arrow="horizontal">性别</List.Item>
                    </Picker>
                </List>
                <WhiteSpace/>
                <Button onClick={this.onRegister} type="primary" loading={false} style={{marginHorizontal:10}}>注册</Button>
            </ScrollView>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        //alignItems:'center',
        //justifyContent:'center'
    }
})