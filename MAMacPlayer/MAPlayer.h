//
//  MAPlayer.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/11.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MAPlayer : NSObject

@property (nonatomic, weak) NSView *view;

+ (instancetype)shareInstance;

@end

NS_ASSUME_NONNULL_END
