//
//  MAVideoFrameBuffer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/9/15.
//

#import "MAVideoFrameBuffer.h"

@interface MAVideoFrameBuffer ()
{
    NSLock *_lock;
}

@property (nonatomic, strong) NSMutableArray* frameBuffer;
@property (nonatomic, assign) NSUInteger maxCount;

@end

@implementation MAVideoFrameBuffer

- (instancetype)initWithMaxCount:(NSUInteger)maxCount
{
    self = [super init];
    if (self) {
        if (maxCount == 0) maxCount = 10;
        _maxCount = maxCount;
        _lock = [[NSLock alloc] init];
        _frameBuffer = [NSMutableArray array];
    }
    return self;
}

- (int)count
{
    int count = 0;
    [_lock lock];
    count = (int)_frameBuffer.count;
    [_lock unlock];
    return count;
}

- (BOOL)enqueueFrame:(MAVideoFrame *)frame
{
    [_lock lock];
    if (frame && _frameBuffer.count < _maxCount) {
        [_frameBuffer addObject:frame];
        [_lock unlock];
        return YES;
    }
    [_lock unlock];
    return NO;
}

- (MAVideoFrame *)dequeueFrame
{
    MAVideoFrame *frame = NULL;
    [_lock lock];
    if (_frameBuffer.count > 0) {
        frame = _frameBuffer[0];
        [_frameBuffer removeObjectAtIndex:0];
        [_lock unlock];
        return frame;
    }
    [_lock unlock];
    return frame;
}

- (MAVideoFrame *)fristFrame
{
    MAVideoFrame *frame = NULL;
    [_lock lock];
    if (_frameBuffer.count > 0) {
        frame = _frameBuffer[0];
        [_lock unlock];
        return frame;
    }
    [_lock unlock];
    return frame;
}

@end

