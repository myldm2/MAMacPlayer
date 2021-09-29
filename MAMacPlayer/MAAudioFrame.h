//
//  MAAudioFrame.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/9/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MAAudioFrame : NSObject

@property (nonatomic, strong) NSData* data;
@property (nonatomic, assign) double pts;
@property (nonatomic, assign) int numSamples;
@property (nonatomic, assign) int sampleRate;

@end

NS_ASSUME_NONNULL_END
