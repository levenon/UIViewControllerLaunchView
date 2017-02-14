//
//  UIViewController+Launcher.h
//  pyyx
//
//  Created by Anna on 16/12/15.
//  Copyright © 2016年 Chunlin Ma. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIViewControllerLaunchViewDelegate <NSObject>

- (NSUInteger)numberOfItemsForLauncherInViewController:(UIViewController *)viewController;

@optional

- (UIView *)containerViewForLauncherInViewController:(UIViewController *)viewController;

- (UIView *)viewController:(UIViewController *)viewController customViewAtIndex:(NSInteger)index;

- (CGPoint)viewController:(UIViewController *)viewController offsetOfCustomViewAtIndex:(NSInteger)index;

- (CAAnimation *)animationForMovingInLauncherInViewControler:(UIViewController *)viewController;

- (CAAnimation *)animationForMovingOutLauncherInViewControler:(UIViewController *)viewController;

- (BOOL)shouldLoadLauncherAfterViewDidLoadInViewController:(UIViewController *)viewController;

- (BOOL)shouldLoadAgainBeforeLauncherFinishedInViewController:(UIViewController *)viewController;

- (BOOL)shouldDisplayLaunchViewInViewController:(UIViewController *)viewController;

- (BOOL)shouldAllowTapLaunchViewInViewController:(UIViewController *)viewController;

- (void)launchViewDidTapInViewController:(UIViewController *)viewController;

- (void)launchViewDidDismissInViewController:(UIViewController *)viewController;

@end

@interface UIViewController (Launcher)

@property (nonatomic, assign) id<UIViewControllerLaunchViewDelegate>launcher_delegate;

- (void)launcher_dismissAnimated:(BOOL)animated completion:(void (^)())completion;

- (void)launcher_reload;

- (void)launcher_reloadAgain;

- (void)launcher_previous;

- (void)launcher_next;

- (void)launcher_done;

@end
