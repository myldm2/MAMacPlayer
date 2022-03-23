//
//  ff_ffplay_def.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/6/15.
//

#ifndef ff_ffplay_def_h
#define ff_ffplay_def_h

#include "masdl_thread.h"

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>

typedef struct VideoState {
    AVFormatContext    *formatCtx;
    
    AVCodecContext     *videoCodecCtxOrig;
    AVCodecContext     *videoCodecCtx;
    AVCodec            *videoCodec;
    
    AVCodecContext     *audioCodecCtxOrig;
    AVCodecContext     *audioCodecCtx;
    AVCodec            *audioCodec;
    
    struct SwsContext         *videoSwsCtx;
    struct SwrContext         *audioConvertCtx;
    
    int outWidth;
    int outHeight;
    
    double audioPts1;
    double audioPts2;
    
    int width;
    int height;
    
    int videoStreamIndex;
    int audioStreamIndex;
} VideoState;

#endif /* ff_ffplay_def_h */
