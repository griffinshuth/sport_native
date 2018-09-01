import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter,
    Platform,
    TouchableHighlight,
    Image
} from 'react-native'
import {
    Flex,
    WingBlank,
    WhiteSpace,
    Slider,
    Toast,
    Badge,
    SegmentedControl,
    List,
    DatePicker,
    Picker,
    Button
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {connect} from 'dva'
import {get,post} from '../../fetch'

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        const nowTimeStamp = Date.now();
        const now = new Date(nowTimeStamp);
        this.state = {
            begintime:now,
            playercount:["2"],
            durationtime:["300"]
        }
    }

    createShootMatch = async()=>{
        var token = this.props.appNS.token;
        var begintime = this.state.begintime.getTime();
        var durationtime = parseInt(this.state.durationtime[0])
        var count = parseInt(this.state.playercount[0]);

        try{
            var result =  await post('/createShootMatch',{token,begintime,durationtime,count});
            if(result.error){
                Toast.info(result.error);
            }else{
                Toast.info("创建成功");
                this.props.navigation.goBack();
            }
        }catch(e){
            Toast.info("无法连接到服务器")
        }
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="创建投篮比赛"
                    navigation={this.props.navigation}
                />
                <View>
                <List>
                    <DatePicker
                        value={this.state.begintime}
                        onChange={date => this.setState({ begintime:date })}
                    >
                        <List.Item arrow="horizontal">比赛开始时间</List.Item>
                    </DatePicker>
                    <Picker
                        data={[{label:'2人',value:"2"},{label:'3人',value:"3"},{label:'4人',value:"4"}]}
                        cols={1}
                        value={this.state.playercount}
                        onChange={v=>this.setState({playercount:v})}
                    >
                        <List.Item arrow="horizontal">人数</List.Item>
                    </Picker>
                    <Picker
                        data={[
                            {label:'3分钟',value:"180"},
                            {label:'5分钟',value:"300"},
                            {label:'10分钟',value:"600"},
                            {label:'12分钟',value:"720"},
                            {label:'15分钟',value:"900"},
                            {label:'20分钟',value:"1200"},
                            {label:"30分钟",value:"1800"}
                            ]}
                        cols={1}
                        value={this.state.durationtime}
                        onChange={v=>this.setState({durationtime:v})}
                    >
                        <List.Item arrow="horizontal">比赛时长</List.Item>
                    </Picker>
                    <WhiteSpace/>
                    <Button onClick={this.createShootMatch}>创建</Button>
                </List>
                </View>
            </View>
        )
    }
}