//
//  MAPlayer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/11.
//

#import "MAPlayer.h"
#import "MAAudioQueuePlayer.h"
#import "MAVideoQueuePlayer.h"

#import "ff_ffplay_def.h"

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>

#define MAX_AUDIO_FRAME_SIZE 192000

@interface MAPlayer ()
{
    VideoState *_videoState;
    
    AVFormatContext* _formatContext;
    
    AVCodecContext     *_videoCodecCtxOrig;
    AVCodecContext     *_videoCodecCtx;
    AVCodec            *_videoCodec;
    
    AVCodecContext     *_audioCodecCtxOrig;
    AVCodecContext     *_audioCodecCtx;
    AVCodec            *_audioCodec;
    
    
    struct SwsContext  *_video_sws_ctx;
    struct SwrContext  *_audio_convert_ctx;
    
    int _videoStreamIndex;
    int _audioStreamIndex;
    
//    AVPacket _packet;
    
    AVPacket _video_packet;
    AVFrame *_video_frame;
    
    AVPacket _audio_packet;
    AVFrame *_audio_frame;
    
    AVPicture *_picture;
    
    int _frameFinished;
    
    int _width;
    int _height;
    
//    uint8_t _audio_buf[(MAX_AUDIO_FRAME_SIZE * 3) / 2];
//    uint8_t *_audio_buf[AV_NUM_DATA_POINTERS];
    uint8_t *_audio_buf;
    
    BOOL _haveData;
}

@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) MAAudioQueuePlayer *audioPlayer;
@property (nonatomic, strong) MAVideoQueuePlayer *videoPlayer;

@end

@implementation MAPlayer

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static MAPlayer* _instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[MAPlayer alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
//        av_register_all();
        
        _videoState = malloc(sizeof(VideoState));
        
        _audio_buf = malloc(MAX_AUDIO_FRAME_SIZE);
        
        _frameFinished = -1;
        self.imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"mp4"];
        [self setupWithPath:path];
        
        _audioPlayer = [[MAAudioQueuePlayer alloc] initWithVideoState:_videoState];
        _videoPlayer = [[MAVideoQueuePlayer alloc] initWithVideoState:_videoState];
        
//        [self startTimer];
        [self play];
        
        

        
    }
    return self;
}

- (void)setView:(NSView *)view
{
    [_videoPlayer setView:view];
}

- (NSView *)view
{
    return [_videoPlayer view];
}

- (void)play
{
    [self startTimer];
    [_videoPlayer play];
    [_audioPlayer play];
}

- (void)startTimer
{
//    [self readFrame];
    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if ([self readFrame]) {
            [timer invalidate];
        }
    }];
}

- (int)readFrame
{
    if (!_video_frame) {
        _video_frame = av_frame_alloc();
    }
    
    if (!_audio_frame) {
        _audio_frame = av_frame_alloc();
    }
    
    if (!_picture) {
        _picture = (AVPicture*)malloc(sizeof(AVPicture));
        avpicture_alloc(_picture,
                        AV_PIX_FMT_RGBA,
                        _width,
                        _height);
    }
    
    while ([self.videoPlayer needData] || [self.audioPlayer needData]) {
        AVPacket packet;
        int ret = av_read_frame(_formatContext, &packet);
        if (ret) {
            [self.audioPlayer play];
            return ret;
        }
        if (packet.stream_index == _videoStreamIndex) {
            int frameFinished = 0;
            while (frameFinished == 0) {
                
                AVStream *stream = _videoState->formatCtx->streams[packet.stream_index];
                AVRational timeBase = stream->time_base;
                
                AVFrame *frame = av_frame_alloc();
                avcodec_decode_video2(_videoCodecCtx, frame, &frameFinished, &packet);
                [self.videoPlayer enqueueFrame:frame];
                
                NSLog(@"video pts:%f", av_q2d(timeBase) * packet.pts);
                
//                NSLog(@"video pts:%lld  %d  %d", packet.pts, _videoState->videoCodecCtx->time_base.den, _videoState->videoCodecCtx->time_base.num);

//                avcodec_decode_video2(_videoCodecCtx, _video_frame, &frameFinished, &packet);
//                sws_scale(_video_sws_ctx, (uint8_t const * const *)_video_frame->data,
//                          _video_frame->linesize, 0, _video_frame->height,
//                          _picture->data, _picture->linesize);
//
//                NSImage *image = [self converImage:_picture->data[0] bytesPerRow:_picture->linesize[0] width:_width height:_height];
//                [self.videoPlayer.synlock lock];
//                [self.videoPlayer.images addObject:image];
//                [self.videoPlayer.synlock unlock];

                if (frameFinished != 0) {
                    break;
                }

            }
        } else if (packet.stream_index == _audioStreamIndex) {
            int frameFinished = 0;
            while (frameFinished == 0) {
                
                AVStream *stream = _videoState->formatCtx->streams[packet.stream_index];
                AVRational timeBase = stream->time_base;
                
                avcodec_decode_audio4(_audioCodecCtx, _audio_frame, &frameFinished, &packet);
                
                NSLog(@"audio pts:%f", _audio_frame->pts * av_q2d(timeBase));

                int data_size = 2 * 2 * _audio_frame->nb_samples;

                int ret = swr_convert(_audio_convert_ctx,
                            &_audio_buf,
                            MAX_AUDIO_FRAME_SIZE,
                            (const uint8_t **)_audio_frame->data,
                            _audio_frame->nb_samples);
                
                [self.audioPlayer.synlock lock];
                [self.audioPlayer.pcmData appendBytes:_audio_buf length:data_size];
                
                [self.audioPlayer.synlock unlock];
                
                if (frameFinished != 0) {
                    break;
                }
            }
        } else {
            
        }
        av_free_packet(&packet);
    }
        
    return 0;

}

- (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }

    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];

    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
    unsigned char *dataBytes = (unsigned char*)bytes;

    for (NSInteger i = 0; i * 2 + 1 < byteRange.length; i++) {
        uint32_t d = 0;
        d = dataBytes[i * 2] << 8 | dataBytes[i * 2 + 1];
    NSString*hexStr= [NSString stringWithFormat:@"%x", d];

    if([hexStr length] == 2){
     [string appendString:hexStr];

    } else{
      [string appendFormat:@"0%@", hexStr];

    }
        [string appendString:@" "];
    }

    }];
    return string;

}

- (NSImage *)converImage:(uint8_t *)data bytesPerRow:(int)bytesPerRow width:(int)width height:(int)height
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, data, bytesPerRow * height, NULL);  //创建provider
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, bytesPerRow, space, kCGImageAlphaLast | kCGImageByteOrder32Big, dataProvider, NULL, true, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    NSImage *resultImage = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(width, height)];
   
    CGImageRelease(imageRef);
    CGColorSpaceRelease(space);
    return resultImage;
}

- (void)setupWithPath:(NSString *)path
{
    _videoStreamIndex = -1;
    
    if (avformat_open_input(&_formatContext, path.UTF8String, NULL, NULL) != 0) {
        goto __FAIL;
    }
    
    _videoState->formatCtx = _formatContext;
    
    av_dump_format(_formatContext, 0, path.UTF8String, 0);
    
    if (avformat_find_stream_info(_formatContext, NULL) != 0) {
        goto __FAIL;
    }
    
    for (int i = 0; i < _formatContext->nb_streams; i ++) {
        AVStream *stream = _formatContext->streams[i];
        if (AVMEDIA_TYPE_VIDEO == stream->codecpar->codec_type) {
            _videoStreamIndex = i;
        } else if (AVMEDIA_TYPE_AUDIO == stream->codecpar->codec_type) {
            _audioStreamIndex = i;
        }
    }
    
    if (_videoStreamIndex == -1) {
        goto __FAIL;
    }
    
    _videoCodecCtxOrig = _formatContext->streams[_videoStreamIndex]->codec;
    _videoState->videoCodecCtxOrig = _videoCodecCtxOrig;
    
    _videoCodec = avcodec_find_decoder(_videoCodecCtxOrig->codec_id);
    _videoState->videoCodec = _videoCodec;
    
    if (_videoCodec == NULL) {
        goto __FAIL; // Codec not found
    }
    
    _videoCodecCtx = avcodec_alloc_context3(_videoCodec);
    if (avcodec_copy_context(_videoCodecCtx, _videoCodecCtxOrig) != 0) {
        goto __FAIL;
    }
    _videoState->videoCodecCtx = _videoCodecCtx;

    if(avcodec_open2(_videoCodecCtx, _videoCodec, NULL) < 0) {
       goto __FAIL; // Could not open codec
     }
    
    _width = _videoCodecCtx->width;
    _height = _videoCodecCtx->height;
    
    _video_sws_ctx = sws_getContext(_videoCodecCtx->width,
                                    _videoCodecCtx->height,
                                    _videoCodecCtx->pix_fmt,
                                    _videoCodecCtx->width,
                                    _videoCodecCtx->height,
                                    AV_PIX_FMT_RGBA,
                                    SWS_BILINEAR,
                                    NULL,
                                    NULL,
                                    NULL
                                    );
    _videoState->videoSwsCtx = _video_sws_ctx;
    
    
    _audioCodecCtxOrig = _formatContext->streams[_audioStreamIndex]->codec;
    _videoState->audioCodecCtxOrig = _audioCodecCtxOrig;
        
    _audioCodec = avcodec_find_decoder(_audioCodecCtxOrig->codec_id);
    _videoState->audioCodec = _audioCodec;
    
    if (_audioCodec == NULL) {
        goto __FAIL; // Codec not found
    }
    
    _audioCodecCtx = avcodec_alloc_context3(_audioCodec);
    if (avcodec_copy_context(_audioCodecCtx, _audioCodecCtxOrig) != 0) {
        goto __FAIL;
    }
    _videoState->audioCodecCtx = _audioCodecCtx;

    if (avcodec_open2(_audioCodecCtx, _audioCodec, NULL) < 0) {
       goto __FAIL; // Could not open codec
    }
    
    uint64_t in_channel_layout = av_get_default_channel_layout(_audioCodecCtx->channels);
    uint64_t out_channel_layout = in_channel_layout;
    
    _audio_convert_ctx = swr_alloc();
    if(_audio_convert_ctx){
        swr_alloc_set_opts(_audio_convert_ctx,
                           out_channel_layout,
                           AV_SAMPLE_FMT_S16,
                           _audioCodecCtx->sample_rate,
                           in_channel_layout,
                           _audioCodecCtx->sample_fmt,
                           _audioCodecCtx->sample_rate,
                           0,
                           NULL);
    }
    swr_init(_audio_convert_ctx);

    
    return;

__FAIL:
    [self destory];
    return;
}

- (void)destory
{
    if (_formatContext) {
        avformat_free_context(_formatContext);
        _formatContext = NULL;
    }
    if (_videoCodecCtxOrig) {
        avcodec_close(_videoCodecCtxOrig);
        _videoCodecCtxOrig = NULL;
    }
    if (_videoCodecCtx) {
        avcodec_close(_videoCodecCtx);
        _videoCodecCtx = NULL;
    }
    
    free(_audio_buf);
}

@end
