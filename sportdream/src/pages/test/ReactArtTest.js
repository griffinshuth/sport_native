import React from 'react'
import {
    View,
    ART
} from 'react-native'
import ToolBar from '../../Components/ToolBar'

export default class Line extends React.Component{
    render(){
        const path = ART.Path();
        path.moveTo(1,1); //将起始点移动到(1,1) 默认(0,0)
        path.lineTo(300,50); //连线到目标点(300,1)

        return(
            <View style={this.props.style}>
                <ToolBar title="绘图API" navigation={this.props.navigation}/>
                <ART.Surface width={300} height={100}>
                    <ART.Shape d={path} stroke="#000000" strokeWidth={1} />
                </ART.Surface>
            </View>
        )
    }
}