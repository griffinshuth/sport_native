import React from 'react'
import {
    View,
    Text,
    StyleSheet,
    TouchableHighlight
} from 'react-native'

export default class ToolBar extends React.Component{
    render(){
        var showBack = this.props.navigation.state.routeName  != "index";
        if(!showBack&&!this.props.headerLeft&&!this.props.headerRight){
            return (
                <View style={styles.container}>
                    <View style={styles.center}><Text style={{fontSize:24,fontWeight:"bold"}}>{this.props.title}</Text></View>
                </View>
            )
        }
        return <View style={styles.container}>
            {showBack?<View style={styles.back}>
                <TouchableHighlight onPress={()=>this.props.navigation.goBack()}>
                    <Text style={{fontSize:20}}>返回</Text>
                </TouchableHighlight>
            </View>:null}
            {this.props.headerLeft?<View style={styles.left}>{this.props.headerLeft}</View>:showBack?null:<View style={styles.left}></View>}
            <View style={styles.center}><Text style={{fontSize:24,fontWeight:"bold"}}>{this.props.title}</Text></View>
            {this.props.headerRight?<View style={styles.right}>{this.props.headerRight}</View>:showBack?<View style={styles.right}></View>:null}

        </View>
    }
}

const styles = StyleSheet.create({
    container:{
        height:60,
        backgroundColor:"#0099FF",
        paddingTop:16,
        flexDirection:'row'
    },
    back:{
        width:44,
        alignItems:'center',
        justifyContent:'center'
    },
    left:{
        width:44,
        alignItems:'center',
        justifyContent:'center'
    },
    center:{
        flex:1,
        alignItems:'center',
        justifyContent:'center',
    },
    right:{
        width:44,
        alignItems:'center',
        justifyContent:'center'
    }
})