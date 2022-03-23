//
//  MAVideoFrame.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/9/15.
//

#import "MAVideoFrame.h"

@implementation MAVideoFrame

- (void)dealloc
{
    if (self.picture) {
        avpicture_free(self.picture);
        self.picture = nil;
    }
    self.image = nil;
}

@end
