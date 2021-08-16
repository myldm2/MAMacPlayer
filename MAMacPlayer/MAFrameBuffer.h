//
//  MAFrameBuffer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/6/30.
//

#import <Foundation/Foundation.h>
#include <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN

@interface MAFrameBuffer : NSObject

@property (nonatomic, assign, readonly) int count;

- (BOOL)enqueueFrame:(AVFrame *)frame;

- (AVFrame *)dequeueFrame;

- (AVFrame *)fristFrame;

@end

NS_ASSUME_NONNULL_END
