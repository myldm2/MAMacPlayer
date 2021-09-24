//
//  MAVideoFrame.h
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/9/15.
//

#import <Foundation/Foundation.h>
#include <libswscale/swscale.h>
#include <libavutil/time.h>
#include <libavformat/avformat.h>

NS_ASSUME_NONNULL_BEGIN

@interface MAVideoFrame : NSObject

@property (nonatomic, strong) NSImage* image;
@property (nonatomic, assign) AVPicture* picture;
@property (nonatomic, assign) double pts;

@end

NS_ASSUME_NONNULL_END
