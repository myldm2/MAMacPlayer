//
//  MAPlayerViewController.m
//  MAMacPlayer
//
//  Created by 马英伦 on 2021/5/11.
//

#import "MAPlayerViewController.h"
#import "MAPlayer.h"

@interface MAPlayerViewController ()

@end

@implementation MAPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = NSColor.whiteColor.CGColor;
    
    [MAPlayer shareInstance].view = self.view;
    
    
}

@end
