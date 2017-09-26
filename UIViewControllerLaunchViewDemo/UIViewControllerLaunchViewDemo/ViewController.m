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

- (void)awakeFromNib{
    [super awakeFromNib];
    
    self.launcher_delegate = self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (NSArray<UIView *> *)guidViews{
    if (!_guidViews) {
        UIView *view1 = [UIView new];
        view1.backgroundColor = [UIColor redColor];
        
        UIView *view2 = [UIView new];
        view2.backgroundColor = [UIColor blueColor];
        
        _guidViews = @[view1, view2];
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
    return [self view];
}

- (BOOL)shouldLoadAgainBeforeLauncherFinishedInViewController:(UIViewController *)viewController;{
    return YES;
}

- (BOOL)shouldAllowTapLaunchViewInViewController:(UIViewController *)viewController{
    return YES;
}

- (BOOL)shouldLoadLauncherAfterViewDidLoadInViewController:(UIViewController *)viewController{
    return YES;
}

@end
