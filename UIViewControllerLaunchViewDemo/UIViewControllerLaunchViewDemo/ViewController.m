//
//  ViewController.m
//  UIViewControllerLaunchViewDemo
//
//  Created by xulinfeng on 2017/2/14.
//  Copyright © 2017年 xulinfeng. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+Launcher.h"

@interface ViewController ()<UIViewControllerLaunchViewDelegate>

@property (nonatomic, strong) NSArray<UIView *> *guidViews;

@end

@implementation ViewController

- (instancetype)init{
    if (self = [super init]) {
        self.launcher_delegate = self;
    }
    return self;
}

- (NSArray<UIView *> *)guidViews{
    if (!_guidViews) {
        _guidViews = @[[UIView new]];
    }
    return _guidViews;
}

#pragma mark - UIViewControllerLaunchViewDelegate

- (NSUInteger)numberOfItemsForLauncherInViewController:(UIViewController *)viewController {
    return [[self guidViews] count];
}

- (UIView *)viewController:(UIViewController *)viewController customViewAtIndex:(NSInteger)index {
    return [self guidViews][index];
}

- (UIView *)containerViewForLauncherInViewController:(UIViewController *)viewController {
    return [[[UIApplication sharedApplication] delegate] window];
}

- (BOOL)shouldLoadAgainBeforeLauncherFinishedInViewController:(UIViewController *)viewController;{
    return YES;
}

- (BOOL)shouldAllowTapLaunchViewInViewController:(UIViewController *)viewController{
    return NO;
}

- (BOOL)shouldLoadLauncherAfterViewDidLoadInViewController:(UIViewController *)viewController{
    return YES;
}

@end
