import React from 'react'
import {
    View,
    Text,
    Image,
    TouchableHighlight
} from 'react-native'
import {
    Button,
    Card,
    WhiteSpace,
    WingBlank,
    Flex,
    Toast
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import emitter from '../../utils/SingleEventEmitter'

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            offIndex:-1,
            onIndex:-1
        }
    }
    render(){
        var team = this.props.navigation.state.params.team;
        var teamMembers = this.props.navigation.state.params.teamMembers;
        var membersOffCourt = this.props.navigation.state.params.membersOffCourt;
        return (
            <View>
                <ToolBar title="换人" navigation={this.props.navigation} />
                <View>
                    <WingBlank size="lg">
                        <WhiteSpace/>
                        <Flex>
                            <Flex.Item style={{alignItems:"center"}}><Text>换下：{this.state.offIndex == -1?"未选择":teamMembers[this.state.offIndex].nickname}</Text></Flex.Item>
                            <Flex.Item style={{alignItems:"center"}}><Text>换上：{this.state.onIndex == -1?"未选择":membersOffCourt[this.state.onIndex].nickname}</Text></Flex.Item>
                        </Flex>
                        <WhiteSpace size="lg" />
                        <Card>
                            <Card.Header
                                title="场上球员"
                            />
                            <Card.Body>
                                <Flex>
                                    {
                                        teamMembers.map((item,index)=>{
                                            return <Flex.Item style={{alignItems:"center"}} key={index}>
                                                <TouchableHighlight onPress={
                                                    ()=>{
                                                        this.setState({offIndex:index})
                                                    }
                                                }>
                                                    <Image style={{width:44,height:54,borderRadius:10,borderColor:'blue',borderWidth:1}} source={{uri:item.image}}/>
                                                </TouchableHighlight>
                                                <Text>{item.nickname}</Text>
                                            </Flex.Item>
                                        })
                                    }
                                </Flex>
                            </Card.Body>
                        </Card>
                        <WhiteSpace size="lg" />
                        <Card>
                            <Card.Header
                                title="场下球员"
                            />
                            <Card.Body>
                                <Flex>
                                    {
                                        membersOffCourt.map((item,index)=>{
                                            return <Flex.Item style={{alignItems:"center"}} key={index}>
                                                <TouchableHighlight onPress={
                                                    ()=>{
                                                        this.setState({onIndex:index})
                                                    }
                                                }>
                                                    <Image style={{width:44,height:54,borderRadius:10,borderColor:'blue',borderWidth:1}} source={{uri:item.image}}/>
                                                </TouchableHighlight>
                                                <Text>{item.nickname}</Text>
                                            </Flex.Item>
                                        })
                                    }
                                </Flex>
                            </Card.Body>
                        </Card>
                        <WhiteSpace/>
                        <Button onClick={
                            ()=>{
                                if(this.state.offIndex>=0 && this.state.onIndex >=0){
                                    var off_uid = teamMembers[this.state.offIndex].id;
                                    var on_uid = membersOffCourt[this.state.onIndex].id;
                                    emitter.emit("playerChanged",{team,off_uid,on_uid})
                                }else{
                                    Toast.info("请选择球员",1)
                                }
                            }
                        }>换人</Button>
                        <WhiteSpace/>
                        <TouchableHighlight onPress={()=>{
                            if(this.state.offIndex>=0 && this.state.onIndex >=0){
                                var off_uid = teamMembers[this.state.offIndex].id;
                                var on_uid = membersOffCourt[this.state.onIndex].id;
                                emitter.emit("playerChanged",{team,off_uid,on_uid})
                            }else{
                                Toast.info("请选择球员",1)
                            }
                        }}>
                            <Text>换人</Text>
                        </TouchableHighlight>
                    </WingBlank>
                </View>
            </View>
        )
    }
}