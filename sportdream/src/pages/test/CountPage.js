import React,{Component} from 'react'
import {
    StyleSheet,
    Text,
    View,
    TouchableHighlight,
    ScrollView,
    Platform,
    Dimensions,
    PixelRatio,
    Image,
} from 'react-native'

import {
    NativeModules,
    requireNativeComponent,
    DeviceEventEmitter
} from 'react-native'
var BaiduMapModule = NativeModules.BaiduMapModule;
var QiniuModule = NativeModules.QiniuModule;
var BaiduMapView = requireNativeComponent('BaiduMapView',null);


import {NavigationActions} from 'react-navigation'

import {connect} from 'dva'
import {
    Button,
    Tabs,
    Badge,
    List,
    Drawer,
    Card,
    Carousel,
    Grid,
    Toast,
    WhiteSpace
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'

const sidebar = (<List>

            <List.Item key={1}
                               thumb="https://zos.alipayobjects.com/rmsportal/eOZidTabPoEbPeU.png"
                               multipleLine
            >Category</List.Item>

        <List.Item key={2}
                           thumb="https://zos.alipayobjects.com/rmsportal/eOZidTabPoEbPeU.png"
        >Category{2}</List.Item>
</List>);

const griddata = Array.from(new Array(9)).map((_val, i) => ({
    icon: 'https://os.alipayobjects.com/rmsportal/IptWdCkrtkAUfjE.png',
    text: `名字${i}`,
}));

const tabs = [
    { title: 'First Tab' },
    { title: 'Second Tab' },
    { title: 'Third Tab' },
];


@connect(({count})=>({count}))
export default class Count extends Component{
    static navigationOptions = {
        title:"计数游戏"
    }

    constructor(props){
        super(props);
        this.state = {
            drawerOpen:false,
            mapCenter:null,
            mapZoom:18,
            marker:null,
            markers:[
                {
                    longitude:108.87054948249285,
                    latitude:34.208124837239254,
                    title:"洛杉矶湖人",
                    icontype:2
                }
            ],
            basketballCourt:[]
        }
    }

    onOpenChange = (isOpen) => {
        console.log('是否打开了 Drawer', (isOpen).toString());
        this.state.drawerOpen = isOpen;
    }

    componentDidMount(){
        console.log("countPages componentDidMount!!!!")
        const {dispatch,count} = this.props;
        dispatch({type:'count/addDelay'})

    }

    onChange(key) {
        console.log('onChange', key);
    }

    onTabClick(key) {
        console.log('onTabClick', key);
    }

    onGetLocation = () => {
        Toast.loading("获得位置中...",0);
        if(Platform.OS =='ios'){
            navigator.geolocation.getCurrentPosition((position)=>{
                Toast.hide();
                Toast.info(JSON.stringify(position));
            },(error)=>{
                Toast.hide();
                Toast.info(JSON.stringify(error.message))
            },{enableHighAccuracy:true,timeout:20000,maximumAge:1000})
        }else{
            BaiduMapModule.getCurrentPosition();
            DeviceEventEmitter.once('onGetCurrentLocationPosition',(result)=>{
                Toast.hide();
                Toast.info(JSON.stringify(result));
            })
        }
    }

    H264Record(){
        QiniuModule.h264Record();
    }

    agoraRemoteCamera(){
        QiniuModule.agoraRemoteCamera();
    }

    render(){
        var windowHeight = Dimensions.get('window').height;
        var contentHeight = windowHeight - 41 - (Platform.OS == 'ios'?60:48);

        const {dispatch,count} = this.props;
        return (
            <View style={styles.container}>
                <ToolBar
                    headerRight={<Badge text={9}>
                        <TouchableHighlight onPress={() => {
                            if(this.drawer){
                                if(this.state.drawerOpen){
                                    this.drawer.closeDrawer();
                                }else{
                                    this.drawer.openDrawer();
                                }
                            }
                        }}>
                        <Image source={require('../../assets/images/shoot.png')} style={{width:28,height:28}}/>
                        </TouchableHighlight>
                    </Badge>}
                    title="计数游戏" navigation={this.props.navigation} />
                <Drawer
                    sidebar={sidebar}
                    position="right"
                    open={false}
                    drawerRef={(el) => this.drawer = el}
                    onOpenChange={this.onOpenChange}
                    drawerBackgroundColor="#ccc"
                >
                <View style={{ flex: 1}}>
                    <Tabs swipeable={false} tabs={tabs}
                          initialPage={1} onChange={this.onChange} onTabClick={this.onTabClick}>

                            <View style={{ height:contentHeight,backgroundColor:'white' }}>
                                <ScrollView style={{flex:1}}>
                                    <Carousel
                                        style={styles.wrapper}
                                        autoplayTimeout={2}
                                        selectedIndex={2}
                                        autoplay
                                        infinite
                                        afterChange={this.onselectedIndexChange}
                                    >
                                        <View style={[styles.carouselStyle, { backgroundColor: 'red' }]}>
                                            <Text>Carousel 1</Text>
                                        </View>
                                        <View style={[styles.carouselStyle, { backgroundColor: 'blue' }]}>
                                            <Text>Carousel 2</Text>
                                        </View>
                                        <View style={[styles.carouselStyle, { backgroundColor: 'yellow' }]}>
                                            <Text>Carousel 3</Text>
                                        </View>
                                        <View style={[styles.carouselStyle, { backgroundColor: 'black' }]}>
                                            <Text>Carousel 4</Text>
                                        </View>
                                        <View style={[styles.carouselStyle, { backgroundColor: '#ccc' }]}>
                                            <Text>Carousel 5</Text>
                                        </View>
                                    </Carousel>
                                    <Grid data={griddata} columnNum={3} isCarousel onClick={(_el, index) => alert(index)} />
                                    <Text>
                                        Count:{count}=={contentHeight}
                                    </Text>
                                    <TouchableHighlight onPress={()=>{dispatch({type:'count/add'})}}>
                                        <Text>Add</Text>
                                    </TouchableHighlight>
                                    <TouchableHighlight onPress={()=>{dispatch({type:'count/addDelay'})}}>
                                        <Text>Delay Add</Text>
                                    </TouchableHighlight>
                                    <Text>{JSON.stringify(this.props.navigation)}</Text>
                                    <WhiteSpace/>
                                    <Button onClick={this.onGetLocation}>获得地理位置</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.H264Record}>Android H264 Record</Button>
                                    <WhiteSpace/>
                                    <Button onClick={this.agoraRemoteCamera}>比赛远程摄像头</Button>
                                    <WhiteSpace/>
                                    <WhiteSpace/>
                                </ScrollView>
                            </View>


                            <View style={{ alignItems: 'center', justifyContent: 'center', height: 400 }}>
                                <Text>选项卡二内容</Text>
                            </View>


                            <View style={{ alignItems: 'center', justifyContent: 'center', height: 100 }}>
                                <Text>选项卡三内容</Text>
                            </View>

                    </Tabs>
                </View>
                </Drawer>
            </View>

        )
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        alignItems: 'center',
        backgroundColor: '#f5fcff'
    },
    carouselStyle:{
        flexGrow: 1,
        alignItems: 'center',
        justifyContent: 'center',
        height: 150,
    }
})
