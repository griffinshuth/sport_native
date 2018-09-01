import React from 'react'
import {
    View,
    Text,
    NativeModules,
    NativeEventEmitter,
    Platform,
    TouchableHighlight,
    Image
} from 'react-native'
import {
    Flex,
    WingBlank,
    WhiteSpace,
    Slider,
    Toast,
    Badge,
    SegmentedControl,
    List,
    DatePicker,
    Picker,
    Button,
    TextareaItem,
    ImagePicker
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import {connect} from 'dva'
import {get,post} from '../../fetch'
var QiniuModule = NativeModules.QiniuModule;
const QiniuModuleEmitter = new NativeEventEmitter(QiniuModule);
import {uploadurl,cloudStorageDomain} from '../../fetch'

@connect(({appNS})=>({appNS}))
export default class App extends React.Component{
    constructor(props){
        super(props);
        const nowTimeStamp = Date.now();
        const now = new Date(nowTimeStamp);
        this.state = {
            text:"",
            images:[]
        }
    }

    componentDidMount(){
        this.uploadProgress_subscription = QiniuModuleEmitter.addListener(
            'uploadProgress',
            (result) => {
                Toast.info("进度："+result.percent);
            }
        );
    }

    componentWillUnmount(){
        this.uploadProgress_subscription.remove();
    }

    onChange = (images, type, index) => {
        this.setState({
            images,
        });
    }

    createTimeLine = async()=>{
        if(this.state.text == ""){
            Toast.info("文本框不能为空",1)
            return;
        }
        if(this.state.images.length == 0){
            Toast.info("图片不能为空",1)
            return;
        }
        //首先上传图片到cdn中，然后获得URLs
        var imageurls = [];
        for(var i=0;i<this.state.images.length;i++){
            var localpath = this.state.images[i].url;
            var width = this.state.images[i].width;
            var height = this.state.images[i].height;
            var pathResult = await QiniuModule.getFilePathByAssetsPath(localpath,width,height);

            var result = await QiniuModule.upload(pathResult.FilePath,uploadurl);
            var url = cloudStorageDomain + result.name;
            imageurls.push(url);
        }

        var token = this.props.appNS.token;
        var text = this.state.text;
        var images = imageurls;
        try{
            var result =  await post('/createTimeLine',{token,text,images});
            if(result.error){
                Toast.info(result.error);
            }else{
                Toast.info("创建成功");
                this.props.navigation.goBack();
            }
        }catch(e){
            Toast.info("无法连接到服务器")
        }
    }

    render(){
        return (
            <View style={{flex:1}}>
                <ToolBar
                    title="创建动态"
                    navigation={this.props.navigation}
                />
                <View>
                    <List>
                        <TextareaItem
                            placeholder="你的动态"
                            rows={5}
                            count={100}
                            value={this.state.text}
                            onChange = {(val)=>this.setState({text:val})}
                        />
                        <WhiteSpace/>
                        <WingBlank>
                            <ImagePicker
                                files={this.state.images}
                                onChange={this.onChange}
                                selectable={this.state.images.length < 10}
                                multiple={true}
                            />
                        </WingBlank>
                        <WhiteSpace/>
                        <Button onClick={this.createTimeLine}>创建</Button>
                    </List>
                </View>
            </View>
        )
    }
}