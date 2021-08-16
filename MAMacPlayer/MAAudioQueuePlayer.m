//
//  MAAudioQueuePlayer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/14.
//

#import "MAAudioQueuePlayer.h"

#define QUEUE_BUFFER_SIZE 4         //队列缓冲个数
#define EVERY_READ_LENGTH 1024*4      //每次从文件读取的长度
#define MIN_SIZE_PER_FRAME 1024*4     //每侦最小数据长度

@interface MAAudioQueuePlayer ()
{
    AudioStreamBasicDescription audioDescription;             //音频参数
    AudioQueueRef audioQueue;                                 //音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
    VideoState *_videoState;
}

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
        self.pcmData = [NSMutableData data];
        self.synlock = [[NSLock alloc] init];
        [self initAudio];
    }
    return self;
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

- (BOOL)needData
{
    BOOL needData = NO;
    [self.synlock lock];
    needData = self.pcmData.length < 1024 * 50;
    [self.synlock unlock];
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
    [self.synlock lock];
    
    if (self.pcmData.length == 0) {
        outQB->mAudioDataByteSize = MIN_SIZE_PER_FRAME;
        memset(outQB->mAudioData, 0, MIN_SIZE_PER_FRAME);
    } else if (self.pcmData.length >= MIN_SIZE_PER_FRAME) {
        NSData *data = [self.pcmData subdataWithRange:NSMakeRange(0, MIN_SIZE_PER_FRAME)];
        self.pcmData = [NSMutableData dataWithData:[self.pcmData subdataWithRange:NSMakeRange(data.length, self.pcmData.length - data.length)]];
        outQB->mAudioDataByteSize = (UInt32)data.length;
        memcpy(outQB->mAudioData, data.bytes, data.length);
    } else {
        NSData *data = [self.pcmData subdataWithRange:NSMakeRange(0, self.pcmData.length)];
        self.pcmData = nil;
        outQB->mAudioDataByteSize = (UInt32)data.length;
        memcpy(outQB->mAudioData, data.bytes, data.length);
    }

    int ret = AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
    [self.synlock unlock];
}



@end
