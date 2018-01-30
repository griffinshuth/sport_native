
export default {
    getMatchState: function(state) {
        if(state == 1){
            return "球员邀请中"
        }else if(state == 2){
            return "临时球队创建中"
        }else if(state == 3){
            return "赛制确定中"
        }else if(state == 4){
            return "准备完毕"
        }else if(state == 5){
            return "比赛进行中"
        }else if(state == 6){
            return "比赛结束"
        }
    },
    getMatchType:function(type) {
        if (type == 1) {
            return "野球赛"
        } else if (type == 2) {
            return "友谊赛"
        } else if (type == 3) {
            return "联赛"
        } else if (type == 4) {
            return "杯赛"
        } else if (type == 5) {
            return "官方比赛"
        }
    },
    getSportType:function(type){
        if(type == 1){
            return "篮球"
        }else if(type == 2){
            return "足球"
        }else if(type == 3){
            return "羽毛球"
        }
    },

    getSportImage:function (type) {
        if(type == 1){
            return require("../assets/images/basketball.png")
        }else if(type == 2){
            return require("../assets/images/football.png")
        }
    },

    getHowWinType:function (type) {
        if(type == 1){
            return "比分"
        }else if(type == 2){
            return "时间"
        }
    },

    getCourtType:function (type) {
        if(type == 1){
            return "半场"
        }else if(type == 2){
            return "全场"
        }
    }
}