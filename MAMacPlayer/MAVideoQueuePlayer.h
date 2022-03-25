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
#import "MAVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MAVideoQueuePlayerDelegate <NSObject>

- (void)videoQueuePlayerIsReady;

@end



@interface MAVideoQueuePlayer : NSObject

@property (nonatomic, weak) id<MAVideoQueuePlayerDelegate> delegate;

@property (nonatomic, weak) NSView *view;

@property (nonatomic, strong) NSLock* aysLock;

@property (nonatomic, strong) NSMutableArray* images;

- (instancetype)initWithVideoState:(VideoState *)videoState;

- (void)play;

- (BOOL)needData;

- (void)enqueueFrame:(MAVideoFrame *)frame;

- (void)prepareToPlay:(void(^)(BOOL))complate;

- (void)playFrameBetween:(double)time1 time2:(double)time2;





@end

NS_ASSUME_NONNULL_END
