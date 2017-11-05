import React from 'react'
import {
    View,
    Text,
    StyleSheet
} from 'react-native'
import {
    Toast,
    Button
} from 'antd-mobile'

import ToolBar from '../../Components/ToolBar'
let BluetoothCP = require("react-native-bluetooth-cross-platform")

export default class app extends React.Component{
    constructor(props){
        super(props);
    }
    componentDidMount() {
        BluetoothCP.advertise("WIFI-BT");
    }
    componentWillUnmount() {

    }
    nearBy(){
        BluetoothCP.getNearbyPeers(function(peers){
            Toast.info(JSON.stringify(peers));
        })
    }
    render(){
        return <View>
            <ToolBar title="跨平台P2P" navigation={this.props.navigation}/>
            <View>
                <Button onClick={()=>this.nearBy()}>搜索</Button>
            </View>
        </View>
    }
}