export default {
    login:function(deviceID,type,name){
        return {id:"login",deviceID:deviceID,type:type,name:name}
    },
    highlight_startplay(state){
        return {id:'highlight_startplay',state:state}
    },
    initDecoder(){
        return {id:'initDecoder'}
    },
    getNewestSmallIFrame(){
        return {id:'getNewestSmallIFrame'}
    },
    getNextSmallFrame(frameindex){
        return {id:'getNextSmallFrame',frameindex:frameindex}
    },
    seekFrontIFrame(frameindex,interval){
        return {id:'seekFrontIFrame',frameindex:frameindex,interval:interval}
    },
    seekBackIFrame(frameindex,interval){
        return {id:'seekBackIFrame',frameindex:frameindex,interval:interval}
    },
    matchDataLogin:function (deviceID) {
        return {id:"matchDataLogin",deviceID:deviceID}
    },
    highlightsLogin:function(deviceID){
        return {id:"highlightsLogin",deviceID:deviceID}
    }
}