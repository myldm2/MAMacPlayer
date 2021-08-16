//
//  MAVideoQueuePlayer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/26.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <libavformat/avformat.h>
#import "ff_ffplay_def.h"

NS_ASSUME_NONNULL_BEGIN

@interface MAVideoQueuePlayer : NSObject

@property (nonatomic, weak) NSView *view;

@property (nonatomic, strong) NSMutableArray<NSImage *> *images;

@property (nonatomic, strong) NSLock *synlock;

- (instancetype)initWithVideoState:(VideoState *)videoState;

- (void)play;

- (BOOL)needData;

- (void)enqueueFrame:(AVFrame *)frame;

@end

NS_ASSUME_NONNULL_END
