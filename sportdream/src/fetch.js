var release = "http://sportlive.2310live.com"
var debug = "http://192.168.0.108"
var server = debug;  //此处是切换服务器地址的地方

export var serverurl = server;
export var uploadurl = server+"/getUploadToken?bucket=grassroot"
export var cloudStorageDomain = "http://grassroot.qiniudn.com/"

var oldFetchfn = fetch; //拦截原始的fetch方法
var fetchwithTimeout = function(input, opts){//定义新的fetch方法，封装原有的fetch方法
    return new Promise(function(resolve, reject){
        var timeoutId = setTimeout(function(){
            reject(new Error("fetch timeout"))
        }, opts.timeout);
        oldFetchfn(input, opts).then(
            res=>{
                clearTimeout(timeoutId);
                resolve(res)
            },
            err=>{
                clearTimeout(timeoutId);
                reject(err)
            }
        )
    })
}

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
    return fetchwithTimeout(uri,{
        method:'GET',
        timeout:5000,
        headers:{
            Accept: 'application/json',
            'Content-Type': 'application/json',
        }
    }).then(filterStatus).then(filterJSON)
}

export async function post(url,body){
    const uri = server + encodeURI(url);
    return fetchwithTimeout(uri,{
        method:'POST',
        timeout:5000,
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