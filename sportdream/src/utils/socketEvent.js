export const clientEvent = {
    otherEnterRoom:1,
    otherLeaveRoom:2,
    initRoomInfo:3,
    updatePermission:4,
    updateChat:5,
    updateTime:6,
    updateScore:7,
    updateTimeout:8,
    updateBallControl:9,
    updateFoul:10,
    updateShoot:11,
    updateFreethrow:12,
    updateRebound:13,
    updateAssist:14,
    updateSteal:15,
    updateFault:16,
    updateBlock:17,
    updateSubstitution:18,
    updateMVPofGame:19,
}

//服务器收到的事件
export const serverEvent = {
    login:1,
    logout:2,
    enterRoom:3,
    leaveRoom:4,
    setPermission:5,
    chat:6,
    picture:7,
    shortVideo:8,
    updateTime:9,
    updateScore:10,
    updateTimeout:11,
    updateBallControl:12,
    updateFoul:13,
    updateShoot:14,
    updateFreethrow:15,
    updateRebound:16,
    updateAssist:17,
    updateSteal:18,
    updateFault:19,
    updateBlock:20,
    updateSubstitution:21,
    updateMVPofGame:22,
    unsetPermission:23
}

export const permissionType = {
    updateTime:9,
    updateScore:10,
    updateTimeout:11,
    updateBallControl:12,
    updateFoul:13,
    updateShoot:14,
    updateFreethrow:15,
    updateRebound:16,
    updateAssist:17,
    updateSteal:18,
    updateFault:19,
    updateBlock:20,
    updateSubstitution:21,
    updateMVPofGame:22,
}

export const admin_op = {
    insquad:1, //进入大名单
    startup:2, //确定首发
    update_time:3,//更新时间，例如每节剩余时间，24秒等
    update_score:4,//更新分数
    update_timeout:5,//更新暂停数
    update_ballcontrol:6, //更新球权
    update_Foul:7, //更新犯规
    update_shoot:8, //更新投篮
    update_freethrow:9, //更新罚球
    update_rebound:10, //更新篮板
    update_assists:11, //更新助攻
    update_steals:12,  //更新抢断
    update_fault:13,  //更新失误
    update_block:14,  //更新盖帽
    substitution:15,        //换人
    mvpofgame:16,     //本场MVP
    update_point:17,  //更新球员得分，数据类型：[{point,section,time}]
}
