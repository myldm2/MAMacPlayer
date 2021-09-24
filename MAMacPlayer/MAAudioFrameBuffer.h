//
//  MAVideoFrameBuffer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/9/15.
//

#import <Foundation/Foundation.h>
#import "MAAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface MAAudioFrameBuffer : NSObject

@property (nonatomic, assign, readonly) int count;

- (instancetype)initWithMaxCount:(NSUInteger)maxCount;

- (BOOL)enqueueFrame:(MAAudioFrame *)frame;

- (MAAudioFrame *)dequeueFrame;

- (MAAudioFrame *)fristFrame;

@end

NS_ASSUME_NONNULL_END
