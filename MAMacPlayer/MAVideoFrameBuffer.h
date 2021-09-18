//
//  MAVideoFrameBuffer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/9/15.
//

#import <Foundation/Foundation.h>
#import "MAVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface MAVideoFrameBuffer : NSObject

@property (nonatomic, assign, readonly) int count;

- (instancetype)initWithMaxCount:(NSUInteger)maxCount;

- (BOOL)enqueueFrame:(MAVideoFrame *)frame;

- (MAVideoFrame *)dequeueFrame;

- (MAVideoFrame *)fristFrame;

@end

NS_ASSUME_NONNULL_END
