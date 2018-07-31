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

export var CameraStandView = requireNativeComponent("HighlightView",null);
export var HighlightServerModule = NativeModules.HighlightViewManager;
export const HighlightServerModuleEmitter = NativeAppEventEmitter;