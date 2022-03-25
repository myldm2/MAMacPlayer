//
//  MATimer.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2022/3/24.
//

#import "MATimer.h"
#include "masdl_thread.h"
#include <libavutil/time.h>

@interface MATimer ()
{
    SDL_Thread *_timerThread;
}

@property (nonatomic, assign) uint64_t baseTime;
@property (nonatomic, assign) uint64_t currentTime;

@end

@implementation MATimer

- (uint64_t)time
{
    return _currentTime = _baseTime;
}

- (void)start
{
    self.baseTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [self setupThread];
}

int ma_timer_timerAction(void *data)
{
    BOOL run = YES;
    while (run) {
        
        MATimer* timer = (MATimer*)CFBridgingRelease(data);
        
        if (timer.delay <= 0) {
            run = NO;
        } else {
            av_usleep((unsigned int)(timer.delay));
        }
        
        NSLog(@"mayinglun log");
    }
    return 0;
}

- (void)setupThread
{
    _timerThread = malloc(sizeof(SDL_Thread));
    SDL_CreateThreadEx(_timerThread, ma_timer_timerAction, (void *)CFBridgingRetain(self), "MA timer thread");
}

@end
