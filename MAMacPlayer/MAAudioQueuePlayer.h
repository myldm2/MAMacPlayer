//
//  MAAudioQueuePlayer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ff_ffplay_def.h"
#import "MAAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MAAudioQueuePlayerDelegate <NSObject>

- (void)audioQueuePlayerIsReady;

- (void)willPlayAudioBetweenStart:(double)start end:(double)end;

@end

@interface MAAudioQueuePlayer : NSObject

@property (nonatomic, weak) id<MAAudioQueuePlayerDelegate> delegate;

@property (nonatomic, strong) NSMutableData* pcmData;

@property (nonatomic, strong) NSLock *synlock;

- (instancetype)initWithVideoState:(VideoState *)videoState;

//- (void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB;

- (BOOL)needData;

- (void)play;

- (void)enqueueFrame:(MAAudioFrame *)frame;

- (void)prepareToPlay:(void(^)(BOOL))complate;

@end

NS_ASSUME_NONNULL_END
