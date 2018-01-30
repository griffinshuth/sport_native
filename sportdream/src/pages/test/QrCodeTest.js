import React from 'react'
import {
    StyleSheet,
    View,
} from 'react-native'

import QRCode from 'react-native-qrcode'
import ToolBar from '../../Components/ToolBar'

export default class App extends React.Component{
    state = {
        text:'text'
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="二维码" navigation={this.props.navigation}/>
                <View style={styles.container}>
                <QRCode
                value={this.state.text}
                size={200}
                bgColor="purple"
                fgColor="white"
                />
                </View>
            </View>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        backgroundColor:'white',
        alignItems:'center',
        justifyContent:'center'
    }
})