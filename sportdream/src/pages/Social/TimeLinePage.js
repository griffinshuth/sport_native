import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter,
    Platform,
    TouchableHighlight,
    TouchableWithoutFeedback,
    Image,
    ScrollView,
    Dimensions,
    TextInput,
    KeyboardAvoidingView
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
    Button,
    TextareaItem,
    ImagePicker,
    Carousel
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {connect} from 'dva'

@connect(({appNS,TimeLine})=>({appNS,TimeLine}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            showimages:false,
            showurls:[],
            selectedIndex:0,
            showinput:false,
            comment:"",
            timelineuid:-1,
        }
    }

    componentWillMount(){
        var token = this.props.appNS.token;
        this.props.dispatch({type:"TimeLine/getAllTimeLine",payload:{

        }})
    }

    componentDidMount(){

    }

    componentWillUnmount(){

    }

    sendComment = (iszan,text,timelineuid)=>{
        if(!iszan){
            if(text == ""){
                Toast.info("评论不能为空");
                return;
            }
        }
        var token = this.props.appNS.token;
        this.props.dispatch({type:"TimeLine/sendTimeLineComment",payload:{token,timelineuid,iszan,text}})
    }

    render(){
        var {loading,timelines} = this.props.TimeLine;
        var {height, width} = Dimensions.get('window');
        return (
            <KeyboardAvoidingView  behavior='padding' style={{flex:1}}>
            {!this.state.showimages?<View style={{flex:1}}>
                <ToolBar
                    title="运动圈"
                    navigation={this.props.navigation}
                />
                <ScrollView>
                    {
                        loading?<Text>加载中</Text>:timelines.length==0?<Text>当前运动圈数据为空</Text>:
                            timelines.map( (item,index) => {
                                //处理该条动态的评论，把赞和文字分开
                                var zans = [];
                                var texts = [];
                                var zanlist = "赞你的人："
                                for(var i=0;i<item.comments.length;i++){
                                    if(item.comments[i].iszan){
                                        zans.push(item.comments[i])
                                        zanlist += item.comments[i].userinfo.nickname+"，";
                                    }else{
                                        texts.push(item.comments[i])
                                    }
                                }

                                zanlist = zanlist.substr(0,zanlist.length-1);
                                return (
                                    <View key={item.timeline_uid} style={{borderBottomWidth:1,borderColor:'#ccc'}}>
                                        <WingBlank>
                                            <View style={{flexDirection:'row'}}>
                                                <Image style={{width:44,height:44,borderRadius:5,marginRight:20}}
                                                       source={{uri:item.userinfo.headerimage}}/>
                                                <View style={{flex:1}}>
                                                    <Text style={{fontSize:20,fontWeight:'bold'}}>{item.userinfo.nickname}</Text>
                                                    <WhiteSpace/>
                                                    <View>
                                                        <Flex wrap="wrap">
                                                            {
                                                                item.images.map((url,imageindex)=>{
                                                                    return <TouchableWithoutFeedback
                                                                        key={imageindex}
                                                                    onPress={()=>{
                                                                            this.setState({
                                                                                showimages:true,
                                                                                showurls:item.images,
                                                                                selectedIndex:imageindex
                                                                            })
                                                                        }
                                                                    }
                                                                    >
                                                                        <Image
                                                                        style={{width:80,height:80,marginLeft:5}}
                                                                        source={{uri:url}}/>
                                                                    </TouchableWithoutFeedback>
                                                                })
                                                            }
                                                        </Flex>
                                                    </View>
                                                    <WhiteSpace/>
                                                    <View>
                                                        <Text>{item.text}</Text>
                                                    </View>
                                                    <WhiteSpace/>
                                                    <View style={{flexDirection:'row'}}>
                                                        <View style={{flex:1,flexDirection:'row',justifyContent:"flex-start"}}>
                                                            <Text>时间</Text>
                                                        </View>
                                                        <View style={{flex:1,flexDirection:'row',justifyContent:"flex-end"}}>
                                                            <Button onClick={
                                                                ()=>this.setState({
                                                                    showinput:true,
                                                                    timelineuid:item.timeline_uid
                                                                })
                                                            } >评论</Button>
                                                            <Button onClick={()=>{
                                                                this.sendComment(true,"",item.timeline_uid);
                                                            }}>赞</Button>
                                                        </View>
                                                    </View>
                                                    <WhiteSpace/>
                                                    <View>{zans.length>0?<Text>{zanlist}</Text>:""}</View>
                                                    <WhiteSpace/>
                                                    <View>
                                                        {
                                                            texts.map((comment,index)=>{
                                                                var t = comment.userinfo.nickname+":"+comment.text;
                                                                return <View key={index}>
                                                                    <Text>{t}</Text>
                                                                </View>
                                                            })
                                                        }
                                                    </View>
                                                </View>
                                            </View>
                                        </WingBlank>
                                    </View>
                                )
                            })
                    }
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>nihao</Text>
                    <Text>end</Text>
                </ScrollView>
                {
                    this.state.showinput?
                        <View
                            style={{
                                position:'absolute',
                                backgroundColor:"#eee",
                                bottom:0,
                                right:10,
                                left:20,
                            }}
                        ><TextInput
                            autoFocus
                            style={{
                                height: 40,
                                borderWidth:1,
                                borderColor:'#ccc',
                            }}
                            placeholder="你的评论"
                            returnKeyType="send"
                            onChangeText={(comment) => this.setState({comment})}
                            onBlur={()=>this.setState({showinput:false,timelineuid:-1})}
                            onSubmitEditing = {()=>{this.sendComment(false,this.state.comment,this.state.timelineuid)}}
                        /></View> :null
                }
            </View>:<View>
                <Carousel selectedIndex={this.state.selectedIndex}
                >
                {
                    this.state.showurls.map((url,index)=>{
                        return <Image key={index} style={{width:width,height:height}} source={{uri:url}}></Image>

                    })
                }
            </Carousel>
                <Button onClick={()=>{
                    this.setState({
                        showimages:false,
                        showurls:[],
                        selectedIndex:0
                    })
                }
                } style={{position:'absolute',top:20,right:10}} size="small">关闭</Button>
            </View>}
            </KeyboardAvoidingView>
        )
    }
}