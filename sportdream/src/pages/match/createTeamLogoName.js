import React from 'react'
import {connect} from 'dva'
import {
    View,
    Text,
    Image
} from 'react-native'

import {
    Button,
    List,
    InputItem,
    WingBlank,
    WhiteSpace,
    Flex,
    Toast
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {post} from '../../fetch'
import emitter from '../../utils/SingleEventEmitter'

@connect(({user,appNS}) => ({user,appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            logo:"",
            name:""
        }
    }

    createTeamLogo = async() =>{
        if(this.state.name){
            var result = await post('/createTeamLogo',{teamname:this.state.name});
            //Toast.info(JSON.stringify(result));
            this.setState({logo:result.base64});
        }else{
            Toast.info("请填写队名",1)
        }

    }

    uploadLogoAndName = async()=>{
        if(this.state.logo && this.state.name){
            var {showid,teamid} = this.props.navigation.state.params;
            var result = await post("/uploadTeamNameLogo",{
                token:this.props.appNS.token,
                name:this.state.name,
                logo:this.state.logo,
                showid,
                teamid
            });
            if(result.error){
                Toast.info(result.errorinfo,1);
            }else{
                Toast.info("成功",1);
                this.props.navigation.goBack();
                emitter.emit("updateTeamsLogoAndName",{teamid:teamid,name:this.state.name,logo:this.state.logo})
            }
        }
    }

    render(){
        return (
            <View>
                <ToolBar title="队名和队徽" navigation={this.props.navigation} />
                <WingBlank>
                    <WhiteSpace/>
                <List>
                    <List.Item><InputItem onChange={(val)=>this.setState({name:val})}>队名：</InputItem></List.Item>
                    <List.Item>
                        <Flex>
                            {this.state.logo?<Image style={{width:120,height:120}} source={{uri:this.state.logo}}/>:null}
                        <Button onClick={this.createTeamLogo}>随机队徽</Button>
                        </Flex>
                    </List.Item>
                </List>
                <WhiteSpace/>
                <Button onClick={this.uploadLogoAndName}>提交</Button>
                </WingBlank>
            </View>
        )
    }
}