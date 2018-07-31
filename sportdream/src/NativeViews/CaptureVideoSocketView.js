import React,{Component} from 'react';
import {requireNativeComponent} from 'react-native';

var CaptureVideoSocketView = requireNativeComponent("CaptureVideoSocketView",null);

export default class CaptureVideoSocketNativeView extends Component
{
    render(){
        return <CaptureVideoSocketView {...this.props} />
    }
}