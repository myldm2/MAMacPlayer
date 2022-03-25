//
//  MAAudioQueuePlayer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/14.
//

#import "MAAudioQueuePlayer.h"
#import "MAFrameBuffer.h"
#import "MAAudioFrameBuffer.h"

#define MAX_AUDIO_FRAME_SIZE 192000

#define QUEUE_BUFFER_SIZE 4         //队列缓冲个数
#define EVERY_READ_LENGTH 1024*4      //每次从文件读取的长度
#define MIN_SIZE_PER_FRAME 1024*4     //每侦最小数据长度

@interface MAAudioQueuePlayer ()
{
    AudioStreamBasicDescription audioDescription;             //音频参数
    AudioQueueRef audioQueue;                                 //音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
    VideoState *_videoState;
    
    uint8_t *_audio_buf;
}

@property (nonatomic, strong) MAAudioFrameBuffer *frameBuffer;
@property (nonatomic, strong) MAAudioFrame *frame;
@property (nonatomic, assign) NSUInteger frameOffset;
@property (nonatomic, strong) NSData *frameData;
@property (nonatomic, copy) void(^prepareBlock)(BOOL);

@end

@implementation MAAudioQueuePlayer

static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    MAAudioQueuePlayer* play = (__bridge MAAudioQueuePlayer *)input;
    if (outQ && outQB) {
        [play readPCMAndPlay:outQ buffer:outQB];
    }
}

- (instancetype)initWithVideoState:(VideoState *)videoState
{
    self = [super init];
    if (self) {
        _videoState = videoState;
        _audio_buf = malloc(MAX_AUDIO_FRAME_SIZE);
        _frameBuffer = [[MAAudioFrameBuffer alloc] initWithMaxCount:300];
        self.pcmData = [NSMutableData data];
        self.synlock = [[NSLock alloc] init];
        [self initAudio];
    }
    return self;
}

- (void)dealloc
{
    free(_audio_buf);
    if (_frame) {
        
    }
}

-(void)initAudio
{
    ///设置音频参数
    audioDescription.mSampleRate = 44100;//采样率(每秒钟采集多少个信号样本)
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = 2;///单声道
    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据
    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel/8) * audioDescription.mChannelsPerFrame;
    
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame ;
    ///创建一个新的从audioqueue到硬件层的通道
    
    // AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void * )self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue);///使用当前线程播
    // 使用player的内部线程播放 新建输出
    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &audioQueue);//使用player的内部线程播
    
    // 设置音量
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    ////添加buffer区，初始化需要的缓冲区
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        int result =  AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
    }
}

- (void)enqueueFrame:(MAAudioFrame *)frame
{
    [self.frameBuffer enqueueFrame:frame];
    
    if (self.prepareBlock && ![self needData]) {
        self.prepareBlock(YES);
        self.prepareBlock = nil;
    }
    
}

- (BOOL)needData
{
    BOOL needData = self.frameBuffer.count < 100;
//    [self.synlock lock];
//    needData = self.pcmData.length < 1024 * 50;
//    [self.synlock unlock];
    return needData;
}

- (void)play
{
    [self AudioQueueStart];
}

// 开始
-(void)AudioQueueStart
{
    AudioQueueStart(audioQueue, NULL);
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        [self readPCMAndPlay:audioQueue buffer:audioQueueBuffers[i]];
    }
}

// 结束
-(void)AudioQueueStop{
    AudioQueueStop(audioQueue, YES);
}

// 暂停
-(void)AudioQueuePause
{
    AudioQueuePause(audioQueue);
}

-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB
{

    NSData *data = [self getPcmData];
    outQB->mAudioDataByteSize = (UInt32)data.length;
    memcpy(outQB->mAudioData, data.bytes, data.length);
    int ret = AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
    
//    int data_size = 2 * 2 * _audio_frame->nb_samples;
//
//    int ret = swr_convert(_audio_convert_ctx,
//                &_audio_buf,
//                MAX_AUDIO_FRAME_SIZE,
//                (const uint8_t **)_audio_frame->data,
//                _audio_frame->nb_samples);
//
//    [self.audioPlayer.synlock lock];
//    [self.audioPlayer.pcmData appendBytes:_audio_buf length:data_size];
    
    
//    [self.synlock lock];
//    if (self.pcmData.length == 0) {
//        outQB->mAudioDataByteSize = MIN_SIZE_PER_FRAME;
//        memset(outQB->mAudioData, 0, MIN_SIZE_PER_FRAME);
//    } else if (self.pcmData.length >= MIN_SIZE_PER_FRAME) {
//        NSData *data = [self.pcmData subdataWithRange:NSMakeRange(0, MIN_SIZE_PER_FRAME)];
//        self.pcmData = [NSMutableData dataWithData:[self.pcmData subdataWithRange:NSMakeRange(data.length, self.pcmData.length - data.length)]];
//        outQB->mAudioDataByteSize = (UInt32)data.length;
//        memcpy(outQB->mAudioData, data.bytes, data.length);
//    } else {
//        NSData *data = [self.pcmData subdataWithRange:NSMakeRange(0, self.pcmData.length)];
//        self.pcmData = nil;
//        outQB->mAudioDataByteSize = (UInt32)data.length;
//        memcpy(outQB->mAudioData, data.bytes, data.length);
//    }
//
//    int ret = AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
//    [self.synlock unlock];
}


- (NSData *)getPcmData
{
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:MIN_SIZE_PER_FRAME];
    
    while (data.length < MIN_SIZE_PER_FRAME) {
        if (!self.frame || !self.frameData) {
            self.frame = [self.frameBuffer dequeueFrame];
            if (self.frame) {
//                int data_size = 2 * 2 * self.frame->nb_samples;
//                int ret = swr_convert(_videoState->audioConvertCtx,
//                            &_audio_buf,
//                            MAX_AUDIO_FRAME_SIZE,
//                            (const uint8_t **)_frame->data,
//                                      _frame->nb_samples);
//                self.frameData = [NSData dataWithBytes:_audio_buf length:data_size];
                self.frameData = self.frame.data;
            }
        }
        
        double peren = self.frameOffset * 1000.0 / self.frame.sampleRate + self.frame.pts;
        if (!isnan(peren)) {
            _videoState->audioPts2 = _videoState->audioPts1;
            _videoState->audioPts1 = peren;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(willPlayAudioBetweenStart: end:)]) {
                [self.delegate willPlayAudioBetweenStart:_videoState->audioPts2 end: _videoState->audioPts1];
            }
            
//            NSLog(@"mayinglun log:audio start %f", _videoState->audioPts1);  //音频时间戳
//            NSLog(@"mayinglun log:audio end %f", peren);  //音频时间戳
            
        }
        
        
//        NSLog(@"audio test log 2:%@ %d", self.frameData, self.frameBuffer.count);
        if (self.frameData) {
            if (self.frameData.length > self.frameOffset + MIN_SIZE_PER_FRAME) {
                [data appendData:[self.frameData subdataWithRange:NSMakeRange(self.frameOffset, MIN_SIZE_PER_FRAME)]];
                self.frameOffset = self.frameOffset + MIN_SIZE_PER_FRAME;
            } else {
                [data appendData:[self.frameData subdataWithRange:NSMakeRange(self.frameOffset, self.frameData.length - self.frameOffset)]];
//                av_frame_free(&self->_frame);
                self.frame = nil;
                self.frameData = nil;
                self.frameOffset = 0;
            }
        } else {
            unsigned long length = MIN_SIZE_PER_FRAME - data.length;
            void* emprtData = malloc(length);
            memset(emprtData, 0, length);
            [data appendData:[[NSData alloc] initWithBytes:emprtData length:length]];
        }
    }
    
    return [data copy];
}

- (void)prepareToPlay:(void(^)(BOOL))complate
{
    self.prepareBlock = complate;
}

@end
