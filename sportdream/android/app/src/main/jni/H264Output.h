//
// Created by lili on 2018/5/12.
//

#ifndef SPORTDREAM_H264OUTPUT_H
#define SPORTDREAM_H264OUTPUT_H
#include <android/native_window.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include "video_gl_surface_render.h"
#include "egl_core.h"
#include "CommonTools.h"

class H264Output {
public:
    H264Output();
    ~H264Output();

    bool initOutput(ANativeWindow* window,int screenWidth,
                    int screenHeight,int texWidth,int texHeight,void* rgbabuffer);
    void stopOutput();

    bool createEGLContext();
    void createWindowSurface();
    bool renderVideo();
    void destroyWindowSurface();
    void destroyEGLContext();

private:
    EGLCore* eglCore;
    EGLSurface renderTexSurface;
    ANativeWindow* surfaceWindow;
    VideoGLSurfaceRender* renderer;

    int screenWidth;
    int screenHeight;
    int texWidth;
    int texHeight;
    bool renderingEnabled;
    void* buffer;
    GLuint texID;

    pthread_t threadId;
    static void* threadStart(void *myself);
    void renderLoop();

};


#endif //SPORTDREAM_H264OUTPUT_H
