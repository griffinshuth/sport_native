import React from 'react'
import {View,StyleSheet,Alert} from 'react-native'

import Barcode from 'react-native-smart-barcode'
import emitter from '../../utils/SingleEventEmitter'
import ToolBar from '../../Components/ToolBar'

class BarcodeTest extends React.Component{
    constructor(props){
        super(props);
        this.state = {
            viewAppear:false
        }
        this.isFirst = true;
    }

    _onBarCodeRead = (e) => {
        console.log(`e.nativeEvent.data.type = ${e.nativeEvent.data.type}, e.nativeEvent.data.code = ${e.nativeEvent.data.code}`)
        this._stopScan();
        if(this.isFirst){
            this.isFirst = false;
            emitter.emit("scanQRCode",e.nativeEvent.data.code);
            this.props.navigation.goBack();
        }
        /*Alert.alert(e.nativeEvent.data.type, e.nativeEvent.data.code, [
            {text: 'OK', onPress: () => this._startScan()},
        ])*/

    }

    _startScan = (e) => {
        this._barCode.startScan()
    }

    _stopScan = (e) => {
        this._barCode.stopScan()
    }

    render(){
        return (
            <View style={{flex:1,backgroundColor:'black'}}>
                <ToolBar title="扫一扫" navigation={this.props.navigation}/>
                <Barcode
                    style={{flex:1}}
                    ref={component=>this._barCode=component}
                    onBarCodeRead={this._onBarCodeRead}
                />
            </View>
        )
    }
}

export default BarcodeTest;