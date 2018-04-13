//
//  VideoFilterTool.m
//  sportdream
//
//  Created by lili on 2018/3/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "VideoFilterTool.h"
#import "libavfilter/avfiltergraph.h"
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>

@implementation VideoFilterTool
{
  AVFrame* frame_in;
  AVFrame* frame_out;
  AVFilterContext* buffersink_ctx;
  AVFilterContext* buffersrc_ctx;
  AVFilterGraph* filter_graph;
  int in_width;
  int in_height;
  NSString* filter_descr;
  AVFilter* buffersrc;
  AVFilter* buffersink;
  AVFilterInOut* outputs;
  AVFilterInOut* inputs;
  AVBufferSinkParams* buffersink_params;
}
-(id)initWith:(int)width height:(int)height
{
  self = [super init];
  if(self){
    in_width = width;
    in_height = height;
    avfilter_register_all();
    filter_descr = @"boxblur";
    buffersrc = avfilter_get_by_name("buffer");
    buffersink = avfilter_get_by_name("buffersink");
    outputs = avfilter_inout_alloc();
    inputs = avfilter_inout_alloc();
    filter_graph = avfilter_graph_alloc();
    char args[512];
    snprintf(args, sizeof(args),
             "video_size=%dx%d:pix_fmt=%d:time_base=%d/%d:pixel_aspect=%d/%d",
             in_width,in_height,AV_PIX_FMT_NV12,
             1, 25,1,1);
    int ret = avfilter_graph_create_filter(&buffersrc_ctx, buffersrc, "in", args, NULL, filter_graph);
    if(ret<0){
      NSLog(@"Cannot create buffer source");
    }
    buffersink_params = av_buffersink_params_alloc();
    enum PixelFormat pix_fmts[] = {AV_PIX_FMT_NV12,PIX_FMT_NONE};
    buffersink_params->pixel_fmts = pix_fmts;
    ret = avfilter_graph_create_filter(&buffersrc_ctx, buffersink, "out", NULL, buffersink_params, filter_graph);
    if(ret<0){
      NSLog(@"Cannot create buffer sink");
    }
    outputs->name = av_strdup("in");
    outputs->filter_ctx = buffersrc_ctx;
    outputs->pad_idx = 0;
    outputs->next = NULL;
    
    inputs->name = av_strdup("out");
    inputs->filter_ctx = buffersink_ctx;
    inputs->pad_idx = 0;
    inputs->next = NULL;
    
    ret = avfilter_graph_parse_ptr(filter_graph, [filter_descr UTF8String], &inputs, &outputs, NULL);
    avfilter_inout_free(&outputs);
    avfilter_inout_free(&inputs);
    if(ret<0){
      NSLog(@"avfilter_graph_parse_ptr err!!!");
    }
    ret = avfilter_graph_config(filter_graph, NULL);
    if(ret<0){
      NSLog(@"avfilter_graph_config error!!!");
    }
    frame_in = avcodec_alloc_frame();
    frame_out = avcodec_alloc_frame();
  }
  return self;
}

-(void)dealloc
{
  av_frame_free(&frame_in);
  av_frame_free(&frame_out);
  avfilter_graph_free(&filter_graph);
}

-(void)processFilter:(uint8_t*)y_frame uv_frame:(uint8_t*)uv_frame
{
  size_t y_size = in_width * in_height;
  size_t uv_size = y_size / 2;
  frame_in->data[0] = y_frame;
  frame_in->data[1] = uv_frame;
  frame_in->width = in_width;
  frame_in->height = in_height;
  frame_in->format = AV_PIX_FMT_NV12;
  
  av_buffersrc_add_frame(buffersrc_ctx, frame_in);
  av_buffersink_get_frame(buffersink_ctx, frame_out);
  //处理滤镜后的数据
  
  av_frame_unref(frame_out);
}

@end
