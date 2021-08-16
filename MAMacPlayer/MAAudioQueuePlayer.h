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

NS_ASSUME_NONNULL_BEGIN

@interface MAAudioQueuePlayer : NSObject

@property (nonatomic, strong) NSMutableData* pcmData;

@property (nonatomic, strong) NSLock *synlock;

- (instancetype)initWithVideoState:(VideoState *)videoState;

- (void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB;

- (BOOL)needData;

- (void)play;

@end

NS_ASSUME_NONNULL_END
