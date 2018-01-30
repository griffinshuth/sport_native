import React from 'react'
import {} from 'antd-mobile'
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

    getApState = async()=>{
        var result = await WiFiAPModule.getWifiAPConfig();
        this.setState({apState:JSON.stringify(result)})
    }

    componentDidMount(){
        this.getApState();
    }
    render(){
        return (
            <View>
                <ToolBar title="创建热点" navigation={this.props.navigation}/>
                <Text>{this.state.apState}</Text>
            </View>
        )
    }
}