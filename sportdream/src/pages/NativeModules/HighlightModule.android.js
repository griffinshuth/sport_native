import {
    View,
    Text,
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    requireNativeComponent,
    Platform,
    ScrollView,
    TouchableHighlight,
    Image
} from 'react-native'

export var CameraStandView = requireNativeComponent("CameraStandView",null);
export var HighlightServerModule = NativeModules.HighlightServerModule;
export const HighlightServerModuleEmitter = new NativeEventEmitter(HighlightServerModule);