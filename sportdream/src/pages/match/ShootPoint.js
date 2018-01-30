import React, { Component } from 'react';
import {
    View,
    Text,
    Dimensions,
    PanResponder,
    Image
} from 'react-native'
import {
    Toast,
    Flex,
    ActionSheet,
    Card,
    WhiteSpace,
    WingBlank,
    Button
} from 'antd-mobile'
import Canvas,{Image as CanvasImage} from 'react-native-canvas';
import ToolBar from '../../Components/ToolBar'
import emitter from '../../utils/SingleEventEmitter'

var PITCH_LENGTH = 28.0;
var PITCH_WIDTH = 15.0;
var PITCH_HALF_LENGTH = PITCH_LENGTH * 0.5;
var PITCH_HALF_WIDTH = PITCH_WIDTH * 0.5;
var PITCH_MARGIN = 1.0;
var CENTER_CIRCLE_R = 1.8;
var PAINT_ZONE_WIDTH = 4.9;
var PAINT_ZONE_HEIGHT = 5.8;
var RING_R = 0.45/2;
var RING_DISTANCE = 1.575;
var BACKBOARD_WIDTH = 1.8;
var BACKBOARD_DISTANCE = 1.2;
var THREE_DISTANCE = 6.75;
var FREETHROW_R = 1.8;
var RestrictedArea_DISTANCE = 1.25;
var HELI_LINE_LEN = 0.375;

var MIN_FIELD_SCALE = 1.0;

function Options(){
    this.M_canvas_width = -1;
    this.M_canvas_height = -1;
    this.M_zoomed = false;
    this.M_field_scale = 1;
    this.M_field_center = {x:0,y:0};

}
Options.prototype.updateFieldSize = function(canvas_width,canvas_height){
    this.M_canvas_width = canvas_width;
    this.M_canvas_height = canvas_height;

    var total_pitch_l = PITCH_LENGTH+PITCH_MARGIN * 2.0+1;
    var total_pitch_w = PITCH_WIDTH+PITCH_MARGIN*2.0;

    this.M_field_scale = canvas_height/total_pitch_l;

    var field_width = canvas_width;

    if(total_pitch_w*this.M_field_scale > field_width){
        this.M_field_scale = field_width/total_pitch_w;
    }

    if(this.M_field_scale < MIN_FIELD_SCALE){
        this.M_field_scale = MIN_FIELD_SCALE;
    }

    this.M_field_center.x = field_width/2;
    this.M_field_center.y = canvas_height/2;

}
Options.prototype.scale = function(len){
    return len*this.M_field_scale;
}

Options.prototype.screenX = function(x){
    return this.M_field_center.x + this.scale(x);
}
Options.prototype.screenY = function(y){
    return this.M_field_center.y + this.scale(y);
}
Options.prototype.fieldX = function(x){
    return (x-this.M_field_center.x)/this.M_field_scale;
}
Options.prototype.fieldY = function(y){
    return (y - this.M_field_center.y)/this.M_field_scale;
}

function drawLine(context,left,top,right,bottom){
    context.strokeStyle = "#fff";
    context.lineWidth = 2;
    context.beginPath();
    context.moveTo(left,top);
    context.lineTo(right,bottom);
    context.stroke();
}

function drawCircle(context,x,y,radius) {
    context.fillStyle = "#ccc"
    context.beginPath();
    context.arc(x,y,radius,0,2*Math.PI);
    context.stroke();
    context.fill();
}

function drawColorCircle(context,x,y,radius,color) {
    context.fillStyle = color
    context.beginPath();
    context.arc(x,y,radius,0,2*Math.PI);
    context.stroke();
    context.fill();
}

function drawHalfCircle(context,x,y,radius,clock) {
    context.beginPath();
    context.arc(x,y,radius,0,Math.PI,clock);
    context.stroke();
}

export default class App extends Component {

    constructor(props){
        super(props);
        var shoots = this.props.navigation.state.params.shoot_array.map((item)=>{return item})
        var freethrows = this.props.navigation.state.params.freethrow_array.map((item)=>{return item})
        this.state = {
            shoot_array:shoots,
            freethrow_array:freethrows,
            player_uid:this.props.navigation.state.params.player.id,
            nickname:this.props.navigation.state.params.player.nickname,
            image:this.props.navigation.state.params.player.image,
            game_uid:this.props.navigation.state.params.game_uid
        }

        this._panResponder = PanResponder.create({
            onStartShouldSetPanResponder: (evt, gestureState) => true,
            onStartShouldSetPanResponderCapture: (evt, gestureState) => true,
            onMoveShouldSetPanResponder: (evt, gestureState) => true,
            onMoveShouldSetPanResponderCapture: (evt, gestureState) => true,
            onPanResponderGrant: (evt,gestureState) => {
                var p = {x:evt.nativeEvent.locationX,y:evt.nativeEvent.locationY}
                //Toast.info(JSON.stringify(p),1)
                //this.ctx.drawImage(this.duihao, p.x, p.y, 16, 16);
                const BUTTONS = ['2分打铁', '2分命中','3分打铁', '3分命中', 'Delete', '取消'];
                ActionSheet.showActionSheetWithOptions({
                        options: BUTTONS,
                        //cancelButtonIndex: BUTTONS.length - 1,
                        //destructiveButtonIndex: BUTTONS.length - 2,
                        message: '增加投篮点',
                        maskClosable: true
                    },
                    (buttonIndex) => {
                        if(buttonIndex == 0 || buttonIndex == 2){
                            //this.ctx.drawImage(this.chahao, p.x-8, p.y-8, 16, 16);
                            drawColorCircle(this.ctx,p.x,p.y,4,"red")
                            //生成投篮点数据
                            if(buttonIndex == 0){
                                var shootpoint = {x:this.opt.fieldX(p.x),y:this.opt.fieldY(p.y),point:2,score:false}
                            }else{
                                var shootpoint = {x:this.opt.fieldX(p.x),y:this.opt.fieldY(p.y),point:3,score:false}
                            }
                            this.state.shoot_array.push(shootpoint);
                            this.setState({shoot_array:this.state.shoot_array})
                            emitter.emit("onAddShoot",{shootpoint,player_uid:this.state.player_uid})
                        }else if(buttonIndex == 1 || buttonIndex == 3){
                            //this.ctx.drawImage(this.duihao, p.x-8, p.y-8, 16, 16);
                            drawColorCircle(this.ctx,p.x,p.y,4,"blue")
                            //生成投篮点数据
                            if(buttonIndex == 1){
                                var shootpoint = {x:this.opt.fieldX(p.x),y:this.opt.fieldY(p.y),point:2,score:true}
                            }else{
                                var shootpoint = {x:this.opt.fieldX(p.x),y:this.opt.fieldY(p.y),point:3,score:true}
                            }
                            this.state.shoot_array.push(shootpoint);
                            this.setState({shoot_array:this.state.shoot_array})
                            emitter.emit("onAddShoot",{shootpoint,player_uid:this.state.player_uid})
                        }
                    });
            },
            onPanResponderMove:(evt,gestureState) =>{

            },
            onPanResponderRelease:(evt,gestureState)=>{

            },
            onPanResponderTerminate:(evt,gestureState)=>{

            }
        })
    }

    handleCanvas = (canvas) => {
        var {height, width} = Dimensions.get('window');
        width = width;
        canvas.width = width;
        canvas.height = height/2;

        var actualheight = height
        var opt = new Options();
        opt.updateFieldSize(width,actualheight);
        var top_y   = opt.screenY( - PITCH_HALF_LENGTH );
        var bottom_y  = opt.screenY( + PITCH_HALF_LENGTH );
        var left_x    = opt.screenX( - PITCH_HALF_WIDTH );
        var right_x = opt.screenX( + PITCH_HALF_WIDTH );

        //绘制篮球场
        var ctx = canvas.getContext("2d");
        this.ctx = ctx;
        //在给定矩形内清空一个矩形
        ctx.clearRect(0,0,width,actualheight);
        ctx.fillStyle = "#ffcc33"
        ctx.fillRect(0,0,width,actualheight);
        //绘制边线
        drawLine(ctx,left_x,top_y,right_x,top_y);
        drawLine(ctx,right_x,top_y,right_x,bottom_y);
        drawLine(ctx,right_x,bottom_y,left_x,bottom_y);
        drawLine(ctx,left_x,bottom_y,left_x,top_y);

        ctx.fillStyle = "#EC870E"
        var pitch_width = opt.scale(PITCH_WIDTH);
        var pitch_height = opt.scale(PITCH_LENGTH)
        ctx.fillRect(left_x,top_y,pitch_width,pitch_height);


        //绘制中线和中圈
        var center_radius = opt.scale( CENTER_CIRCLE_R );
        drawCircle(ctx,opt.M_field_center.x,opt.M_field_center.y,center_radius);
        drawLine(ctx,left_x,opt.M_field_center.y,right_x,opt.M_field_center.y);

        //绘制油漆区
        var paint_left_x = opt.screenX(-PAINT_ZONE_WIDTH*0.5);
        var paint_zone_width = opt.scale(PAINT_ZONE_WIDTH);
        var paint_zone_height = opt.scale(PAINT_ZONE_HEIGHT);
        ctx.fillStyle="#cc0033";
        ctx.fillRect(paint_left_x,top_y,paint_zone_width,paint_zone_height);
        ctx.fillRect(paint_left_x,bottom_y-paint_zone_height,paint_zone_width,paint_zone_height);

        //绘制篮圈,三分线,合理冲撞区
        var ring_y = opt.screenY(-(PITCH_HALF_LENGTH-RING_DISTANCE));
        var ring_r = opt.scale(RING_R);
        var three_r = opt.scale(THREE_DISTANCE);
        var heli_r = opt.scale(RestrictedArea_DISTANCE);
        drawCircle(ctx,opt.M_field_center.x,ring_y,ring_r);     //绘制篮圈
        drawHalfCircle(ctx,opt.M_field_center.x,ring_y,three_r);//绘制三分线
        drawHalfCircle(ctx,opt.M_field_center.x,ring_y,heli_r); //绘制合理冲撞区
        var three_left_x = opt.screenX(-THREE_DISTANCE);
        var three_right_x = opt.screenX(THREE_DISTANCE);
        var three_y = opt.screenY(-(PITCH_HALF_LENGTH-RING_DISTANCE));
        drawLine(ctx,three_left_x,top_y,three_left_x,three_y);
        drawLine(ctx,three_right_x,top_y,three_right_x,three_y);
        ring_y = opt.screenY((PITCH_HALF_LENGTH-RING_DISTANCE));
        drawCircle(ctx,opt.M_field_center.x,ring_y,ring_r);          //绘制篮圈
        drawHalfCircle(ctx,opt.M_field_center.x,ring_y,three_r,true);//绘制三分线
        drawHalfCircle(ctx,opt.M_field_center.x,ring_y,heli_r,true); //绘制合理冲撞区
        three_y = opt.screenY((PITCH_HALF_LENGTH-RING_DISTANCE));
        drawLine(ctx,three_left_x,bottom_y,three_left_x,three_y);
        drawLine(ctx,three_right_x,bottom_y,three_right_x,three_y);

        //修正合理冲撞区
        var heli_left_x = opt.screenX(-RestrictedArea_DISTANCE);
        var heli_right_x = opt.screenX(RestrictedArea_DISTANCE);
        var heli_top_y = opt.screenY(-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE-HELI_LINE_LEN));
        var heli_bottom_y = opt.screenY(-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE))
        drawLine(ctx,heli_left_x,heli_bottom_y,heli_left_x,heli_top_y);
        drawLine(ctx,heli_right_x,heli_bottom_y,heli_right_x,heli_top_y);
        heli_top_y = opt.screenY((PITCH_HALF_LENGTH-BACKBOARD_DISTANCE-HELI_LINE_LEN));
        heli_bottom_y = opt.screenY((PITCH_HALF_LENGTH-BACKBOARD_DISTANCE))
        drawLine(ctx,heli_left_x,heli_bottom_y,heli_left_x,heli_top_y);
        drawLine(ctx,heli_right_x,heli_bottom_y,heli_right_x,heli_top_y);


        //绘制篮板
        var bankboard_left_x = opt.screenX(-BACKBOARD_WIDTH*0.5);
        var bankboard_right_x = opt.screenX(BACKBOARD_WIDTH*0.5);
        var bankboard_y = opt.screenY(-(PITCH_HALF_LENGTH-BACKBOARD_DISTANCE));
        drawLine(ctx,bankboard_left_x,bankboard_y,bankboard_right_x,bankboard_y);
        bankboard_y = opt.screenY((PITCH_HALF_LENGTH-BACKBOARD_DISTANCE));
        drawLine(ctx,bankboard_left_x,bankboard_y,bankboard_right_x,bankboard_y);

        //绘制罚球半圆
        var freethrow_x = opt.M_field_center.x;
        var freethrow_r = opt.scale(FREETHROW_R);
        var freethrow_y = opt.screenY(-(PITCH_HALF_LENGTH-PAINT_ZONE_HEIGHT))
        drawHalfCircle(ctx,freethrow_x,freethrow_y,freethrow_r);
        freethrow_y = opt.screenY((PITCH_HALF_LENGTH-PAINT_ZONE_HEIGHT))
        drawHalfCircle(ctx,freethrow_x,freethrow_y,freethrow_r,true);
        return;
        //打印中点坐标
        //Toast.info(JSON.stringify({x:opt.screenX(0),y:opt.screenY(0)}))
        function circleImg(ctx, img, x, y, r) {
            ctx.save();
            var d =2 * r;
            var cx = x + r;
            var cy = y + r;
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.clip();
            ctx.drawImage(img, x, y, d, d);
            ctx.restore();
        }
        const image = new CanvasImage(canvas);
        image.src = "http://grassroot.qiniudn.com/b498f0f6860fa5f73eb20147b7c088d4.jpeg";
        image.addEventListener('load', () => {
            console.log('image is loaded');
            //ctx.drawImage(image, opt.screenX(0), opt.screenY(0), 50, 50);
            var center_x = parseInt(opt.screenX(0));
            var center_y = parseInt(opt.screenY(0));
            circleImg(ctx,image,center_x-50,center_y-50,50);
        });

        this.duihao = new CanvasImage(canvas);
        this.duihao.src = "http://grassroot.qiniudn.com/duihao.png";
        this.duihao.addEventListener('load', () => {

        })

        this.chahao = new CanvasImage(canvas);
        this.chahao.src = "http://grassroot.qiniudn.com/chahao.png";
        this.chahao.addEventListener('load', () => {

        })


    }

    componentDidMount(){
        this.handleCanvas(this.canvas);
        //绘制投篮点
        var {height, width} = Dimensions.get('window');
        var actualheight = height
        this.opt = new Options();
        this.opt.updateFieldSize(width,actualheight);
        for(var i=0;i<this.state.shoot_array.length;i++){
            var {x,y,point,score} = this.state.shoot_array[i];
            //把逻辑坐标转为物理坐标
            var paint_x = this.opt.screenX(x);
            var paint_y = this.opt.screenY(y);
            if(score){
                drawColorCircle(this.ctx,paint_x,paint_y,4,"blue")
            }else{
                drawColorCircle(this.ctx,paint_x,paint_y,4,"red")
            }
        }
    }

    calculateFreethrow = ()=>{
        var total = 0;
        var score = 0;
        for(var i=0;i<this.state.freethrow_array.length;i++){
            total += this.state.freethrow_array[i].shoot;
            score += this.state.freethrow_array[i].score;
        }
        return score+"/"+total;
    }

    normalFreethrow = (type)=>{
        const BUTTONS = ["两罚全中","两罚一中","两罚全失"];
        ActionSheet.showActionSheetWithOptions({
                options: BUTTONS,
                cancelButtonIndex: BUTTONS.length - 1,
                destructiveButtonIndex: BUTTONS.length - 2,
                message: '普通罚球',
                maskClosable: true
            },
            (buttonIndex) => {
            var freethrow = {type:type,shoot:2,score:2-buttonIndex};
                this.state.freethrow_array.push(freethrow)
                this.setState({freethrow_array:this.state.freethrow_array})
                emitter.emit("addFreethrow",{player_uid:this.state.player_uid,freethrow:freethrow})
            })
    }

    singleFreethrow = (type)=>{
        const BUTTONS = ["罚中","罚失"];
        ActionSheet.showActionSheetWithOptions({
                options: BUTTONS,

                message: '罚球',
                maskClosable: true
            },
            (buttonIndex) => {
            var freethrow = {type:type,shoot:1,score:1-buttonIndex};
                this.state.freethrow_array.push(freethrow)
                this.setState({freethrow_array:this.state.freethrow_array})
                emitter.emit("addFreethrow",{player_uid:this.state.player_uid,freethrow:freethrow})
            })
    }

    render() {
        return (
            <View>
                <ToolBar title="技术统计" navigation={this.props.navigation} />
                <View {...this._panResponder.panHandlers}>
                <Canvas ref={(val)=>{this.canvas=val;}}/>
                </View>
                <Flex>
                    <Flex.Item style={{backgroundColor:'blue'}}><Text>蓝色代表命中</Text></Flex.Item>
                    <Flex.Item style={{backgroundColor:'red'}}><Text>红色代表打铁</Text></Flex.Item>
                </Flex>
                <Flex justify="center"><Image style={{width:44,height:54}} source={{uri:this.state.image}}/></Flex>
                <WingBlank size="lg">
                    <WhiteSpace size="lg" />
                    <Card>
                        <Card.Header
                            title={this.state.nickname+"(号码未知)"}
                            extra={"罚球"}
                        />
                        <Card.Body>
                            <WingBlank>
                                <Flex>
                                    <Flex.Item><Button onClick={()=>{this.normalFreethrow(0)}}>普通罚球</Button></Flex.Item>
                                    <Flex.Item><Button onClick={()=>{this.singleFreethrow(1)}}>技术犯规</Button></Flex.Item></Flex></WingBlank>
                            <WingBlank>
                                <Flex>
                                    <Flex.Item><Button onClick={()=>{this.singleFreethrow(2)}}>2+1</Button></Flex.Item>
                                    <Flex.Item><Button onClick={()=>{this.singleFreethrow(3)}}>3+1</Button></Flex.Item>
                                </Flex>
                            </WingBlank>
                        </Card.Body>
                        <Card.Footer content="位置：未知" extra={"命中率："+this.calculateFreethrow()} />
                    </Card>
                    <WhiteSpace size="lg" />
                </WingBlank>
            </View>
        )
    }
}