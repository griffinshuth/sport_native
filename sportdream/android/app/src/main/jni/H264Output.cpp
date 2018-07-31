//
// Created by lili on 2018/5/12.
//

#include "H264Output.h"
#include <unistd.h>

#define LOG_TAG "VideoOutput"

H264Output::H264Output() {}

H264Output::~H264Output() {}

bool H264Output::initOutput(ANativeWindow *window, int screenWidth, int screenHeight, int texWidth,
                            int texHeight,void* rgbabuffer) {
    this->screenHeight = screenHeight;
    this->screenWidth = screenWidth;
    this->texHeight = texHeight;
    this->texWidth = texWidth;

    this->surfaceWindow = window;
    this->buffer = malloc(texWidth*texHeight*4);
    memcpy(buffer,rgbabuffer,texWidth*texHeight*4);

    pthread_create(&threadId, 0, threadStart, this);
    return true;
}

bool H264Output::createEGLContext() {
    LOGI("enter VideoOutput::createEGLContext");
    eglCore = new EGLCore();
    LOGI("enter VideoOutput use sharecontext");
    bool ret = eglCore->initWithSharedContext();
    if(!ret){
        LOGI("create EGL Context failed...");
        return false;
    }
}

void H264Output::createWindowSurface() {
    renderTexSurface = eglCore->createWindowSurface(surfaceWindow);
    if (renderTexSurface != NULL){
        eglCore->makeCurrent(renderTexSurface);
        // must after makeCurrent
        renderer = new VideoGLSurfaceRender();
        bool isGLViewInitialized = renderer->init(screenWidth, screenHeight);// there must be right：1080, 810 for 4:3
        if (!isGLViewInitialized) {
            LOGI("GL View failed on initialized...");
        } else {

        }
    }
    //eglCore->doneCurrent();
}

void H264Output::destroyEGLContext() {
    if (NULL != eglCore){
        eglCore->release();
        delete eglCore;
        eglCore = NULL;
    }
}

void H264Output::destroyWindowSurface() {
    if (EGL_NO_SURFACE != renderTexSurface){
        if (renderer) {
            renderer->dealloc();
            delete renderer;
            renderer = NULL;
        }

        if (eglCore){
            eglCore->releaseSurface(renderTexSurface);
        }

        renderTexSurface = EGL_NO_SURFACE;
        if(NULL != surfaceWindow){
            LOGI("VideoOutput Releasing surfaceWindow");
            ANativeWindow_release(surfaceWindow);
            surfaceWindow = NULL;
        }
    }
}

void* H264Output::threadStart(void *myself) {
    H264Output *output = (H264Output*) myself;
    output->renderLoop();
    pthread_exit(0);
    return 0;
}

void H264Output::renderLoop() {
    createEGLContext();
    createWindowSurface();
    renderingEnabled = true;
    //创建纹理
    glGenTextures(1,&texID);
    glBindTexture(GL_TEXTURE_2D,texID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,texWidth,texHeight,0,GL_RGBA, GL_UNSIGNED_BYTE,buffer);
    while(renderingEnabled){
        renderVideo();
        usleep(30*1000);
    }
    glBindTexture(GL_TEXTURE_2D,0);
    glDeleteTextures(1,&texID);
    destroyWindowSurface();
    destroyEGLContext();
}

void H264Output::stopOutput() {
    renderingEnabled = false;
    pthread_join(threadId, 0);
    free(buffer);
    LOGI("leave H264Output::stopOutput");
}

bool H264Output::renderVideo() {
    eglCore->makeCurrent(renderTexSurface);
    renderer->renderToViewWithAutoFill(texID, screenWidth, screenHeight,texWidth,texHeight);
    if (!eglCore->swapBuffers(renderTexSurface)) {
        LOGE("eglSwapBuffers(renderTexSurface) returned error %d", eglGetError());
    }
}