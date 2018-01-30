import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    ScrollView
} from 'react-native'
import {
    List,
    InputItem,
    Switch,
    Picker,
    Toast,
    WhiteSpace,
    WingBlank,
    Button
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {get,post} from '../../fetch'
import {NavigationActions} from 'react-navigation'
import emitter from '../../utils/SingleEventEmitter'
import eventtype from '../../utils/EventType'

const StartupNums = [

    {label:'3人',value:"3"},
    {label:'4人',value:"4"},
    {label:'5人',value:"5"},
    {label:'6人',value:"6"},
    {label:'7人',value:"7"},
    {label:'8人',value:"8"},
    {label:'9人',value:"9"},
    {label:'10人',value:"10"},
    {label:'11人',value:"11"},

]

const sporttype = [
    {label:'篮球',value:"1"},
    {label:'足球',value:"2"},
    {label:'羽毛球',value:"3"}
]

const matchFormat = [
    {label:'时间',value:"2"},
    {label:'比分',value:"1"},
]

const matchtime = [
    {label:'5分钟',value:"5"},
    {label:'10分钟',value:"10"},
    {label:'12分钟',value:"12"},
    {label:'20分钟',value:"20"},
    {label:'30分钟',value:"30"},
    {label:'40分钟',value:"40"},
    {label:'48分钟',value:"48"},
]

const sectionnum = [
    {label:'一节',value:'1'},
    {label:'两节',value:'2'},
    {label:'三节',value:'3'},
    {label:'四节',value:'4'},
]

const pointlimit = [
    {label:'5分',value:'5'},
    {label:'8分',value:'8'},
    {label:'10分',value:'10'},
    {label:'15分',value:'15'},
    {label:'20分',value:'20'},
    {label:'25分',value:'25'},
]

const courttype = [
    {label:'半场',value:'1'},
    {label:'全场',value:'2'}
]

@connect(({user,appNS})=>({user,appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            startupnumber:["3"],
            sporttype:["1"],
            matchformat:["2"],
            matchtime:["5"],
            sectionnum:["1"],
            pointlimit:['5'],
            courttype:['1'],
            cityname:""
        }
    }

    createStreetMatch = async()=>{
        var body = {
            from:'app',
            token:this.props.appNS.token,
            cityname:this.state.cityname,
            startnum:this.state.startupnumber[0],
            sporttype:this.state.sporttype[0],
            howwin:this.state.matchformat[0],
            pointwin:this.state.pointlimit[0],
            sectioncount:this.state.sectionnum[0],
            sectiontime:this.state.matchtime[0],
            courttype:this.state.courttype[0]
        }

        //Toast.info(JSON.stringify(body),100)
        var result =  await post("/createStreetMatch",body)
        if(result.error){
            Toast.info("token过期，请重新登录")
        }else{
            //Toast.info("比赛创建成功",1);
            Toast.info(JSON.stringify(result))
            this.props.navigation.goBack();
            emitter.emit(eventtype.ReloadCreatedMatch)
        }
    }

    ipLocation = async()=>{
        var result = await fetch("http://api.map.baidu.com/location/ip?ak=ONLv8ZVG94yKZBPeb7NLOzQ4ZgGuzhUK").then(function(res){return res.json();})
        this.setState({cityname:result.content.address_detail.city});
    }

    componentDidMount(){
        this.ipLocation();
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="创建野球赛" navigation={this.props.navigation}/>
                <ScrollView style={{flex:1}}>
                    <List
                        renderHeader={()=>'创建比赛'}
                    >
                        <Picker
                            data={StartupNums}
                            title="选择人数"
                            cols={1}
                            extra="请选择(可选)"
                            value={this.state.startupnumber}
                            onChange={v=>{this.setState({startupnumber:v})}}
                        >
                            <List.Item arrow="horizontal">首发人数</List.Item>
                        </Picker>

                        <Picker
                            data={sporttype}
                            title="选择体育项目"
                            cols={1}
                            extra="请选择(可选)"
                            value={this.state.sporttype}
                            onChange={v=>{this.setState({sporttype:v})}}
                        >
                            <List.Item arrow="horizontal">体育项目类别</List.Item>
                        </Picker>

                        <Picker
                            data={matchFormat}
                            title="选择赛制"
                            cols={1}
                            extra="请选择(可选)"
                            value={this.state.matchformat}
                            onChange={v=>{this.setState({matchformat:v})}}
                        >
                            <List.Item arrow="horizontal">比赛赛制</List.Item>
                        </Picker>
                        {
                            this.state.matchformat[0] == "2"?
                                <Picker
                                    data={matchtime}
                                    title="选择每节的时间"
                                    cols={1}
                                    extra="请选择(可选)"
                                    value={this.state.matchtime}
                                    onChange={v=>{this.setState({matchtime:v})}}
                                >
                                    <List.Item arrow="horizontal">每节的时间</List.Item>
                                </Picker>
                            :null
                        }
                        {
                            this.state.matchformat[0] == "2"?
                                <Picker
                                    data={sectionnum}
                                    title="比赛分几节"
                                    cols={1}
                                    extra="请选择(可选)"
                                    value={this.state.sectionnum}
                                    onChange={v=>{this.setState({sectionnum:v})}}
                                >
                                    <List.Item arrow="horizontal">比赛节数</List.Item>
                                </Picker>
                                :null
                        }
                        {
                            this.state.matchformat[0] == "1"?
                                <Picker
                                    data={pointlimit}
                                    title="选择分制"
                                    cols={1}
                                    extra="请选择(可选)"
                                    value={this.state.pointlimit}
                                    onChange={v=>{this.setState({pointlimit:v})}}
                                >
                                    <List.Item arrow="horizontal">分制</List.Item>
                                </Picker>
                                :null
                        }
                        <Picker
                            data={courttype}
                            title="选择场地类型"
                            cols={1}
                            extra="请选择(可选)"
                            value={this.state.courttype}
                            onChange={v=>{this.setState({courttype:v})}}
                        >
                            <List.Item arrow="horizontal">场地类型</List.Item>
                        </Picker>

                    </List>
                    <WhiteSpace/>
                    <Button onClick={this.createStreetMatch}>创建</Button>
                </ScrollView>
            </View>
        )
    }
}