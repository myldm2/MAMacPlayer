//
//  MATimer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2022/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MATimer : NSObject

//毫秒位单位
@property (nonatomic, assign) uint32_t delay;
@property (nonatomic, assign, readonly) uint64_t time;

- (void)start;

@end

NS_ASSUME_NONNULL_END
