//
//  MAVideoQueuePlayer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/26.
//

#import "MAVideoQueuePlayer.h"
#import "MAFrameBuffer.h"

#include <libswscale/swscale.h>
#include <libavutil/time.h>
#include <libavformat/avformat.h>
#include "masdl_thread.h"


@interface MAVideoQueuePlayer ()
{
    SDL_Thread *_timerThread;
    MAFrameBuffer *_frameBuffer;
    VideoState *_videoState;
    
    AVPicture *_picture;
}


@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) MAFrameBuffer *frameBuffer;

@end

@implementation MAVideoQueuePlayer

- (instancetype)initWithVideoState:(VideoState *)videoState
{
    self = [super init];
    if (self) {
        _videoState = videoState;
        _frameBuffer = [[MAFrameBuffer alloc] init];
        self.images = [NSMutableArray array];
        self.imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        
        videoState->outHeight = videoState->videoCodecCtx->height;
        videoState->outWidth = videoState->videoCodecCtx->width;
        
        if (!_picture) {
            _picture = (AVPicture*)malloc(sizeof(AVPicture));
            avpicture_alloc(_picture,
                            AV_PIX_FMT_RGBA,
                            videoState->outWidth,
                            videoState->outHeight);
        }
        
        [self setupThread];
    }
    return self;
}

int timerAction(void *data)
{
    while (YES) {
        NSLog(@"mayinglun log timerAction");
        av_usleep(2 * 1000 * 1000);
    }
    return 0;
}

- (void)setupThread
{
    _timerThread = malloc(sizeof(SDL_Thread));
    SDL_CreateThreadEx(_timerThread, timerAction, nil, "timer thread");
}

- (void)play
{
    [self startTimer];
}

- (BOOL)needData
{
    return self.frameBuffer.count <= 10;
//    return self.images.count <= 20;
}

- (void)enqueueFrame:(AVFrame *)frame
{
    if (frame) {
        [self.frameBuffer enqueueFrame:frame];
    }
}

- (void)startTimer
{
    [NSTimer scheduledTimerWithTimeInterval:0.0434 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self showNextImage];
    }];
}

- (void)setView:(NSView *)view
{
    _view = view;
    [view addSubview:self.imageView];
    self.imageView.frame = view.bounds;
}

- (void)showNextImage
{
    AVFrame *frame = [self.frameBuffer dequeueFrame];
    if (frame) {
        sws_scale(_videoState->videoSwsCtx, (uint8_t const * const *)frame->data,
                  frame->linesize, 0, frame->height,
                  _picture->data, _picture->linesize);

        NSImage *image = [self converImage:_picture->data[0] bytesPerRow:_picture->linesize[0] width:_videoState->outWidth height:_videoState->outHeight];
        
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    }
    
//    NSImage *image = nil;
//    [self.synlock lock];
//
//    image = self.images.firstObject;
//    if (image) {
//        [self.images removeObject:image];
//    }
//
//    [self.synlock unlock];
//
//    if (image) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.imageView.image = image;
//        });
//    }
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

@end
