import React, { Component} from 'react';
import { requireNativeComponent } from 'react-native';

var RemoteControlView = requireNativeComponent('RemoteControlView', null);
export default class RemoteControlNativeView extends Component {
    render() {
        return <RemoteControlView {...this.props} />;
    }
}