import React from 'react'
import {
    View,
    Text,
} from 'react-native'
import {
    Flex
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'

export default class App extends React.Component{
    constructor(props){
        super(props);
        this.state = {

        }
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar title="记分牌" navigation={this.props.navigation} />
                <View style={{flex:1,backgroundColor:'black'}}>
                    <View style={{flex:1,alignItems:"center",justifyContent:'center'}}>
                        <Text style={{color:'white',fontSize:120,fontWeight:'bold'}}>12:00</Text>
                    </View>
                    <View style={{flex:2,alignItems:"center",justifyContent:'center'}}>
                        <Text style={{color:'red',fontSize:300,fontWeight:'bold'}}>24</Text>
                    </View>
                </View>
            </View>
        )
    }
}
