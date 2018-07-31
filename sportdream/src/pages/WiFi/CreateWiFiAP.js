import React from 'react'
import {
    Button,
    Toast
} from 'antd-mobile'
import {
    View,
    Text,
    NativeModules
} from 'react-native'

import ToolBar from '../../Components/ToolBar'

var WiFiAPModule = NativeModules.WiFiAPModule;

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            apState:""
        }
    }

    componentDidMount(){
        WiFiAPModule.getWifiApState().then((state)=>{
            if(state){
                Toast.info("热点开启中")
            }else{
                Toast.info("热点关闭中")
            }
        })
    }
    render(){
        return (
            <View>
                <ToolBar title="创建热点" navigation={this.props.navigation}/>
                <Text>{this.state.apState}</Text>
                <Button onClick={()=>{
                    WiFiAPModule.openAPUI();
                }}>打开热点</Button>
            </View>
        )
    }
}