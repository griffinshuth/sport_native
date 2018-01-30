//
// Created by lili on 2017/12/26.
//
#include "com_sportdream_nativec_udp.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>

struct sockaddr_in sin_recv;
int sock;
char udpbuffer[1024*1024];

JNIEXPORT void JNICALL Java_com_sportdream_nativec_udp_init
        (JNIEnv *env, jobject jobject1, jshort port)
{
    sock = socket(AF_INET,SOCK_DGRAM,0);
    bzero(&sin_recv,sizeof(sin_recv));
    sin_recv.sin_family=AF_INET;
    sin_recv.sin_addr.s_addr=htonl(INADDR_ANY);
    sin_recv.sin_port=htons(port);
    //启动广播设置
    int so_broadcast = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &so_broadcast,
                     sizeof(so_broadcast));
    bind(sock,(struct sockaddr *)&sin_recv,sizeof(sin_recv));
}

JNIEXPORT void JNICALL Java_com_sportdream_nativec_udp_close
        (JNIEnv *env, jobject jobject1)
{
    close(sock);
}

JNIEXPORT void JNICALL Java_com_sportdream_nativec_udp_sendto
        (JNIEnv *env, jobject jobject1, jstring ip, jshort port, jbyteArray data)
{
    jbyte * buffer = (jbyte*)(*env)->GetByteArrayElements(env, data, 0);
    struct sockaddr_in address;
    memset(&address,0,sizeof(address));
    address.sin_family = AF_INET;
    const char *str = (*env)->GetStringUTFChars(env, ip, 0);
    address.sin_addr.s_addr = inet_addr(str);
    (*env)->ReleaseStringUTFChars(env, ip, str);
    address.sin_port = htons(port);

    int dest_len = sizeof(struct sockaddr_in);

    jsize len = (*env)->GetArrayLength(env,data); //获取长度

    int send_num = sendto(sock,buffer,len,0,(struct sockaddr *)&address,dest_len);

    (*env)->ReleaseByteArrayElements(env,data,buffer,0);
}

JNIEXPORT jbyteArray JNICALL Java_com_sportdream_nativec_udp_recvfrom
        (JNIEnv * env, jobject jobject1)
{
    struct sockaddr_in sin_source;
    bzero(&sin_source,sizeof(sin_source));
    int sin_len = sizeof(sin_source);
    int bytenum = recvfrom(sock,udpbuffer,sizeof(udpbuffer),0,(struct sockaddr *)&sin_source,&sin_len);
    char* ip = inet_ntoa(sin_source.sin_addr);
    short port = ntohs(sin_source.sin_port);
    jbyteArray  array = (*env)->NewByteArray(env,bytenum);
    (*env)->SetByteArrayRegion(env,array,0,bytenum,udpbuffer);
    return array;
}
