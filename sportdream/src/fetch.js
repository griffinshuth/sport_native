var server = "http://192.168.0.105"

export async function get(url,params){
    var str = "";
    if(params&&Object.keys(params).length > 0){
        str = "?";
        Object.keys(params).map(function(value){
            var temp = value+"="+params[value];
            str += temp;
            str += '&';
        })
        //去掉多余的&
        str = str.substr(0,str.length-1)
    }
    const uri = server + encodeURI(url+str);
    return fetch(uri,{
        method:'GET',
        headers:{
            Accept: 'application/json',
            'Content-Type': 'application/json',
        }
    }).then(filterStatus).then(filterJSON)
}

export async function post(url,body){
    const uri = server + encodeURI(url+str);
    return fetch(uri,{
        method:'POST',
        headers:{
            Accept: 'application/json',
            'Content-Type': 'application/json',
        },
        body:JSON.stringify(body)
    }).then(filterStatus).then(filterJSON);
}

function filterStatus(res){
    if(res.status == 200){
        return res;
    }else{
        const error = new Error();
        error.res = res;
        throw error;
    }
}

function filterJSON(res){
    return res.json();
}

export function promisePost(url,body){
    const uri = server + encodeURI(url);
        return fetch(uri,{
            method:'POST',
            headers:{
                Accept: 'application/json',
                'Content-Type': 'application/json',
            },
            body:JSON.stringify(body)
        }).then(filterStatus).then(filterJSON);
}

export function promiseGet(url,params){
    var str = "";
    if(params&&Object.keys(params).length > 0){
        str = "?";
        Object.keys(params).map(function(value){
            var temp = value+"="+params[value];
            str += temp;
            str += '&';
        })
        //去掉多余的&
        str = str.substr(0,str.length-1)
    }
    const uri = server + encodeURI(url+str);
    return fetch(uri,{
        method:'GET',
        headers:{
            Accept: 'application/json',
            'Content-Type': 'application/json',
        },
    }).then(filterStatus).then(filterJSON);
}