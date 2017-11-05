import React from 'react'
import {
    View,
    Text,
    StyleSheet,
    TouchableHighlight,
    BackHandler,
} from 'react-native'

import {Toast} from 'antd-mobile'

export default class ToolBar extends React.Component{
    androidBack = () => {
        if(this.props.navigation.state.routeName  != "index"){
            this.props.navigation.goBack();
            return true;
        }else{
            return false;
        }
    }
    componentDidMount(){
        BackHandler.addEventListener('hardwareBackPress', this.androidBack)
    }

    componentWillUnmount(){
        //Toast.info(this.props.navigation.state.routeName);
        BackHandler.removeEventListener("hardwareBackPress",this.androidBack);
    }
    render(){
        var showBack = this.props.navigation.state.routeName  != "index";
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
        height:48,
        backgroundColor:"#0099FF",

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