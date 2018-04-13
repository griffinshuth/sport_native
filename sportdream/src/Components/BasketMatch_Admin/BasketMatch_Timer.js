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
    ActionSheet,
    Toast,
    Switch,
    List
} from 'antd-mobile'

import {
    Button,
    WhiteSpace,
    WingBlank,
    Flex,
} from 'antd-mobile'

const styles = StyleSheet.create({
    comment:{
        backgroundColor:'white',
        borderWidth:1,
        borderColor:'#ccc',
        borderRadius:5,
        justifyContent:'center',
        alignItems:'center'
    },
    time_font:{
        fontSize:20,fontWeight:"bold"
    },
    player_flex_item:{
        alignItems:"center"
    },
    timeButton:{
        marginTop:10,
        marginBottom:10
    }
})

export default class BasketMatchTimer extends PureComponent{
    countDown = ()=>{
        const {isTimerStart} = this.props;
        if(!isTimerStart){
            //启动计时器
            this.props.dispatch({type:"CurrentAdminMatchModel/timestart",payload:{isTimerStart:true}})
        }else{
            //停止计时器
            this.props.dispatch({type:"CurrentAdminMatchModel/timestart",payload:{isTimerStart:false}})
            clearInterval(this.handleTimer);
            this.handleTimer = null;
            this.stop24();
        }

    }

    ballControlChange = ()=>{
        const {isTimerStart,team1info,team2info} = this.props;
        const BUTTONS = [];
        BUTTONS.push(team1info.name);
        BUTTONS.push(team2info.name);
        BUTTONS.push("取消")
        ActionSheet.showActionSheetWithOptions({
                options: BUTTONS,
                cancelButtonIndex: BUTTONS.length - 1,
                message: '球权',
                maskClosable: true
            },
            (buttonIndex) => {
                if(buttonIndex == 0 || buttonIndex == 1){
                    var currentattacktime = 24;
                    var ballowner = buttonIndex+1;
                    this.props.dispatch({type:"CurrentAdminMatchModel/ballownerchange",payload:{currentattacktime,ballowner}})
                    if(isTimerStart){
                        //如果正在计时中，则如果24秒定时器是停止的话，启动24秒定时器
                        this.start24();
                    }
                }
            })
    }

    reset24 = ()=>{
        var currentattacktime = 24;
        var ballowner = 0;
        this.props.dispatch({type:"CurrentAdminMatchModel/reset24",payload:{currentattacktime,ballowner}})
        this.stop24();
    }

    start24 = ()=>{
        const {need01,currentattacktime} = this.props;
        if(!this.handle24Timer){
            if(!need01){
                this.handle24Timer = setInterval(()=>{
                    this.props.dispatch({type:"CurrentAdminMatchModel/countdown24",payload:{time:1}})
                },1000)
            }else{
                if(currentattacktime>5){
                    this.handle24Timer = setInterval(()=>{
                        this.props.dispatch({type:"CurrentAdminMatchModel/countdown24",payload:{time:1}})
                    },1000)
                    this.is2401second = false;
                }else{
                    this.handle24Timer = setInterval(()=>{
                        this.props.dispatch({type:"CurrentAdminMatchModel/countdown24",payload:{time:0.1}})
                    },100)
                    this.is2401second = true;
                }
            }
        }
    }

    stop24 = ()=>{
        if(this.handle24Timer){
            clearInterval(this.handle24Timer);
            this.handle24Timer = null;
        }
    }

    changeCountDownStyle = (checked)=>{
        this.props.dispatch({type:"CurrentAdminMatchModel/setCountDownStyle",payload:{need01:checked}})
    }

    componentWillUnmount(){
        if(this.handleTimer){
            clearInterval(this.handleTimer);
            this.handleTimer = null;
        }
        this.stop24();
    }

    render(){
        const {isTimerStart,ballowner,need01,currentsectiontime,currentattacktime} = this.props;
        if(isTimerStart&&!this.handleTimer){
            //reducer同意开始，启动定时器
            if(!need01){
                this.handleTimer = setInterval(()=>{
                    this.props.dispatch({type:"CurrentAdminMatchModel/countdown",payload:{time:1}})
                },1000)
            }else{
                if(currentsectiontime>60){
                    this.handleTimer = setInterval(()=>{
                        this.props.dispatch({type:"CurrentAdminMatchModel/countdown",payload:{time:1}})
                    },1000)
                    this.iscountdown01second = false;
                }else{
                    this.handleTimer = setInterval(()=>{
                        this.props.dispatch({type:"CurrentAdminMatchModel/countdown",payload:{time:0.1}})
                    },100)
                    this.iscountdown01second = true;
                }
            }

            //如果球权归属确定，则启动24秒
            if(ballowner!=0){
                this.start24();
            }
        }
        if(!isTimerStart && this.handleTimer){
            //倒计时停止，但是定时器还没有停止，则自动停止计时器，发生在倒计时为0或24到时的情况
            clearInterval(this.handleTimer);
            this.handleTimer = null;
            this.stop24();
        }

        if(need01){
            if(currentattacktime<=5 && !this.is2401second){
                this.stop24();
                this.start24();
            }
            if(currentsectiontime<=60&&!this.iscountdown01second){
                clearInterval(this.handleTimer);
                this.handleTimer = setInterval(()=>{
                    this.props.dispatch({type:"CurrentAdminMatchModel/countdown",payload:{time:0.1}})
                },100)
                this.iscountdown01second = true;
            }
        }
        return (
                <View style={styles.comment}>
                    <TouchableHighlight style={styles.timeButton} onPress={this.countDown}>
                        <Text style={styles.time_font}>{isTimerStart?"倒计时停止":"倒计时开始"}</Text>
                    </TouchableHighlight>
                    <TouchableHighlight style={styles.timeButton} onPress={this.reset24}>
                        <Text style={styles.time_font}>重置24秒</Text>
                    </TouchableHighlight>
                    <TouchableHighlight style={styles.timeButton} onPress={this.ballControlChange}>
                        <Text style={styles.time_font}>球权转换</Text>
                    </TouchableHighlight>
                    {/*<WhiteSpace/>
                    <List>
                        <List.Item extra={<Switch
                            checked={need01}
                            onChange={(checked)=>{this.changeCountDownStyle(checked)}}
                        />}>倒计时0.1秒</List.Item>
                    </List>
                    <WhiteSpace/>
                <Flex>
                    <Flex.Item><WingBlank><Button onClick={this.countDown} size="large" type="ghost">{isTimerStart?"倒计时停止":"倒计时开始"}</Button></WingBlank></Flex.Item>
                </Flex>
                <WhiteSpace/>
                <Flex>
                    <Flex.Item><WingBlank><Button onClick={this.reset24} size="large" type="ghost">重置24秒</Button></WingBlank></Flex.Item>
                    <Flex.Item><WingBlank><Button onClick={this.ballControlChange} size="large" type="ghost">球权转换</Button></WingBlank></Flex.Item>
                </Flex>
                <WhiteSpace/>
                    <Flex>
                        <Flex.Item><WingBlank><Button onClick={()=>{}} size="large" type="ghost">调整数据</Button></WingBlank></Flex.Item>
                    </Flex>
                    <WhiteSpace/>*/}
            </View>
        )
    }
}

/*const BasketMatchTimer = ({isTimerStart,currentsection,currentsectiontime,currentattacktime,dispatch}) => {
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

    countDown = ()=>{
        dispatch({type:"CurrentAdminMatchModel/countdown"})
    }

    return (
        <View style={styles.comment}>
            <WhiteSpace/>
            <Flex>
                <Flex.Item><WingBlank><Button onClick={countDown} size="large" type="ghost">{isTimerStart?"停止":"开始"}</Button></WingBlank></Flex.Item>
                <Flex.Item><WingBlank><Button onClick={()=>{}} size="large" type="ghost">球权转换</Button></WingBlank></Flex.Item>
            </Flex>
            <WhiteSpace/>
            <Flex>
                <Flex.Item style={styles.player_flex_item}><Text style={styles.time_font}>第{currentsection}节</Text></Flex.Item>
                <Flex.Item style={styles.player_flex_item}><Text style={styles.time_font}>{second2time(currentsectiontime)}</Text></Flex.Item>
                <Flex.Item style={styles.player_flex_item}><Text style={styles.time_font}>{currentattacktime}</Text></Flex.Item>
            </Flex>
            <WhiteSpace/>
            <Flex>
                <Flex.Item><WingBlank><Button onClick={()=>{}} size="large" type="ghost">24秒重置</Button></WingBlank></Flex.Item>
                <Flex.Item><WingBlank><Button onClick={()=>{}} size="large" type="ghost">投篮统计</Button></WingBlank></Flex.Item>
            </Flex>
            <WhiteSpace/>
        </View>
    )
}
export default BasketMatchTimer*/