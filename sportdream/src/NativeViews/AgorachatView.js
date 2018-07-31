import React, { Component} from 'react';
import { requireNativeComponent } from 'react-native';

var AgorachatView = requireNativeComponent('AgorachatView', null);
export default class AgorachatNativeView extends Component {
    render() {
        return <AgorachatView {...this.props} />;
    }
}