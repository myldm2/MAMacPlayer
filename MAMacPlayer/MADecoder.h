//
//  MADecoder.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2022/3/22.
//

#import <Foundation/Foundation.h>
#import "MAVideoFrame.h"
#import "MAAudioFrame.h"
#import "ff_ffplay_def.h"

NS_ASSUME_NONNULL_BEGIN


@protocol MADecoderDelegate <NSObject>

- (BOOL)needData;

- (void)onDecodeVideoFrame:(MAVideoFrame *)videoFrame;

- (void)onDecodeAudioFrame:(MAAudioFrame *)audioFrame;

@end

@interface MADecoder : NSObject

@property (nonatomic, weak) id<MADecoderDelegate> delegate;

- (instancetype)initWithVideoState:(VideoState *)videoState;

- (void)start;

@end

NS_ASSUME_NONNULL_END
