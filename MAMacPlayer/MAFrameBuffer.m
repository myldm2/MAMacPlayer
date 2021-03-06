//
//  MAFrameBuffer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/6/30.
//

#import "MAFrameBuffer.h"

#define MAVideoQueueMaxFrame 20

//@interface MAFrameBuffer ()
//{
//    AVFrame** _frameBuffer;
//    int _index;
//    NSLock *_lock;
//}
//
//@property (nonatomic, assign) int count;
//@property (nonatomic, assign) NSUInteger maxCount;
//
//@end
//
//@implementation MAFrameBuffer
//
//- (instancetype)initWithMaxCount:(NSUInteger)maxCount
//{
//    self = [super init];
//    if (self) {
//        if (maxCount == 0) maxCount = MAVideoQueueMaxFrame;
//        _maxCount = maxCount;
//        _lock = [[NSLock alloc] init];
//        _frameBuffer = malloc(sizeof(AVFrame*) * maxCount);
//        _count = 0;
//        _index = 0;
//    }
//    return self;
//}
//
//- (int)count
//{
//    int count = 0;
//    [_lock lock];
//    count = _count;
//    [_lock unlock];
//    return count;
//}
//
//- (int)currentIndex
//{
//    return _index;
//}
//
//- (int)nextIndex
//{
//    int nextIndex = (_index + 1) % _maxCount;
//    return nextIndex;
//}
//
//- (BOOL)enqueueFrame:(AVFrame *)frame
//{
//    [_lock lock];
//    if (frame && _count < _maxCount) {
//        int nextIndex = ([self currentIndex] + _count) % _maxCount;
//        _frameBuffer[nextIndex] = frame;
//        _count += 1;
//        [_lock unlock];
////        NSLog(@"audio test log write:%d, %d", nextIndex, _count);
//        return YES;
//    }
//    [_lock unlock];
//    return NO;
//}
//
//- (AVFrame *)dequeueFrame
//{
//    AVFrame *frame = NULL;
//    [_lock lock];
//    if (_count > 0) {
//        int currentIndex = [self currentIndex];
////        NSLog(@"audio test log read:%d %d", currentIndex, _count);
//        if (currentIndex >= 0 && currentIndex < _maxCount) {
//            frame = _frameBuffer[currentIndex];
//            _frameBuffer[currentIndex] = nil;
//            _index = [self nextIndex];
//            _count -= 1;
//            [_lock unlock];
////            NSLog(@"audio test log delete:%d, %d", currentIndex, _count);
//            return frame;
//        }
//    }
//    [_lock unlock];
//
//    return frame;
//}
//
//- (AVFrame *)fristFrame
//{
//    AVFrame *frame = NULL;
//    [_lock lock];
//    if (_count > 0) {
//        int currentIndex = [self currentIndex];
//        if (currentIndex >= 0 && currentIndex < _maxCount) {
//            frame = _frameBuffer[currentIndex];
//            [_lock unlock];
//            return frame;
//        }
//    }
//    [_lock unlock];
//    return frame;
//}
//
//@end


@interface MAFrameBuffer ()
{
    NSLock *_lock;
}

@property (nonatomic, strong) NSMutableArray* frameBuffer;
@property (nonatomic, assign) NSUInteger maxCount;

@end

@implementation MAFrameBuffer

- (instancetype)initWithMaxCount:(NSUInteger)maxCount
{
    self = [super init];
    if (self) {
        if (maxCount == 0) maxCount = MAVideoQueueMaxFrame;
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

//NSInteger MASortFrame (id  _Nonnull __strong obj1, id  _Nonnull __strong obj2, void * _Nullable ad)
//{
//    NSValue* value1 = obj1;
//    NSValue* value2 = obj2;
//    AVFrame* frame1 = value1.pointerValue;
//    AVFrame* frame2 = value2.pointerValue;
//    return frame1->pts > frame2->pts;
//}

- (BOOL)enqueueFrame:(AVFrame *)frame
{
    [_lock lock];
    if (frame && _frameBuffer.count < _maxCount) {
        [_frameBuffer addObject:[NSValue valueWithPointer:frame]];
//        [_frameBuffer sortUsingFunction:MASortFrame context:NULL];
        [_lock unlock];
        return YES;
    }
    [_lock unlock];
    return NO;
}

- (AVFrame *)dequeueFrame
{
    AVFrame *frame = NULL;
    [_lock lock];
    if (_frameBuffer.count > 0) {
        NSValue* value = _frameBuffer[0];
        frame = value.pointerValue;
        [_frameBuffer removeObjectAtIndex:0];
        [_lock unlock];
        return frame;
    }
    [_lock unlock];
    return frame;
}

- (AVFrame *)fristFrame
{
    AVFrame *frame = NULL;
    [_lock lock];
    if (_frameBuffer.count > 0) {
        NSValue* value = _frameBuffer[0];
        frame = value.pointerValue;
        [_lock unlock];
        return frame;
    }
    [_lock unlock];
    return frame;
}

@end
