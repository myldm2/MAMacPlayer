//
//  MAVideoQueuePlayer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/26.
//

#import "MAVideoQueuePlayer.h"
#import "MAVideoFrameBuffer.h"

#include <libswscale/swscale.h>
#include <libavutil/time.h>
#include <libavformat/avformat.h>
#include "masdl_thread.h"


@interface MAVideoQueuePlayer ()
{
    SDL_Thread *_timerThread;
    MAVideoFrameBuffer *_frameBuffer;
    VideoState *_videoState;
    
    AVPicture *_picture;
}


@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) MAVideoFrameBuffer *frameBuffer;
@property (nonatomic, copy) void(^prepareBlock)(BOOL);

@end

@implementation MAVideoQueuePlayer

- (instancetype)initWithVideoState:(VideoState *)videoState
{
    self = [super init];
    if (self) {
        _videoState = videoState;
        _frameBuffer = [[MAVideoFrameBuffer alloc] initWithMaxCount:100];
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
        
        
        self.aysLock = [NSLock new];
        self.images = [NSMutableArray array];
        
        [self setupThread];
    }
    return self;
}

int timerAction(void *data)
{
    while (YES) {
//        NSLog(@"mayinglun log timerAction");
//        [self showNextImage];
        av_usleep(43.4 * 1000);
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
//    [self startTimer];
}

- (BOOL)needData
{
    return self.frameBuffer.count <= 10;
}

- (void)enqueueFrame:(MAVideoFrame *)frame
{
    if (frame) {
        [self.frameBuffer enqueueFrame:frame];
    }
    
    if (self.prepareBlock && ![self needData]) {
        self.prepareBlock(YES);
        self.prepareBlock = nil;
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
    MAVideoFrame *frame = [self.frameBuffer dequeueFrame];
    if (frame) {
        NSImage* image = frame.image;
//        NSImage *image = [self converImage:frame.picture->data[0] bytesPerRow:frame.picture->linesize[0] width:_videoState->outWidth height:_videoState->outHeight];

        avpicture_free(frame.picture);
        
//        NSLog(@"mayinglun log frame index:b_%d %p", index, _picture->data[0]);
        
//        static int index = 0;
//        if (index <= 5000) {
//            NSData *imageData = [image TIFFRepresentation];
//            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
//            [imageRep setSize:[[_imageView image] size]];
//            NSData *imageData1 = [imageRep representationUsingType:NSPNGFileType properties:nil];
//            NSLog(@"mayinglun log file path:%@", NSTemporaryDirectory());
//            NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"b_%d.png", index, frame]];
//            [imageData1 writeToFile:path atomically:YES];
//            index ++;
////            NSLog(@"mayinglun log frame index:b_%d %p", index, frame->data[0]);
//        }
        
//        av_frame_free(&frame);

        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    }
    
//    [self.aysLock lock];
//    NSImage* image = nil;
//    if (self.images.count > 0) {
//        image = self.images[0];
//        [self.images removeObjectAtIndex:0];
//        NSLog(@"mayinglun log show frame:%@", image);
//    }
//    [self.aysLock unlock];
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

- (void)prepareToPlay:(void(^)(BOOL))complate
{
    self.prepareBlock = complate;
}

- (void)playFrameBetween:(double)time1 time2:(double)time2
{
    while (YES) {
        MAVideoFrame *frame = [self.frameBuffer fristFrame];
        if (frame) {
            if (frame.pts < time1) {
                [self.frameBuffer dequeueFrame];
            } else if (frame.pts >= time1 && frame.pts < time2) {
                [self.frameBuffer dequeueFrame];
                NSImage* image = frame.image;
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.imageView.image = image;
                    });
                }
                break;
            } else {
                break;
            }
        } else {
            break;
        }
    }
}

@end
