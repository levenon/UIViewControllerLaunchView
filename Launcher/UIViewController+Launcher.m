//
//  UIViewController+GuideView.m
//  pyyx
//
//  Created by Anna on 16/12/15.
//  Copyright © 2016年 Chunlin Ma. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "UIViewController+Launcher.h"

UIKIT_STATIC_INLINE void UIViewControllerLauncherMethodSwizzle(Class class, SEL origSel, SEL altSel){
    Method origMethod = class_getInstanceMethod(class, origSel);
    Method altMethod = class_getInstanceMethod(class, altSel);
    
    class_addMethod(class, origSel, class_getMethodImplementation(class, origSel), method_getTypeEncoding(origMethod));
    class_addMethod(class, altSel, class_getMethodImplementation(class, altSel), method_getTypeEncoding(altMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(class, origSel), class_getInstanceMethod(class, altSel));
}

@interface UIViewController (Launcher_Private)

@property (nonatomic, strong) UIView *launcher_contentView;
@property (nonatomic, strong) UIView *launcher_customView;
@property (nonatomic, assign) NSInteger launcher_currentIndex;

@end

@implementation UIViewController (Launcher)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIViewControllerLauncherMethodSwizzle(self, @selector(viewDidLoad), @selector(launcher_swizzle_viewDidLoad));
        UIViewControllerLauncherMethodSwizzle(self, @selector(viewWillLayoutSubviews), @selector(launcher_swizzle_viewWillLayoutSubviews));
    });
}

- (void)launcher_swizzle_viewDidLoad{
    [self launcher_swizzle_viewDidLoad];
    
    if ([self launcher_delegate] &&
        [[self launcher_delegate] respondsToSelector:@selector(shouldLoadLauncherAfterViewDidLoadInViewController:)] &&
        [[self launcher_delegate] shouldLoadLauncherAfterViewDidLoadInViewController:self]) {
        [self launcher_reload];
    }
}

- (void)launcher_swizzle_viewWillLayoutSubviews{
    [self launcher_swizzle_viewWillLayoutSubviews];
    
    [self _launcher_updateContentSize];
}

#pragma mark - accessor
- (id<UIViewControllerLaunchViewDelegate>)launcher_delegate{
    return objc_getAssociatedObject(self, @selector(launcher_delegate));
}

- (void)setLauncher_delegate:(id<UIViewControllerLaunchViewDelegate>)launcher_delegate{
    objc_setAssociatedObject(self, @selector(launcher_delegate), launcher_delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (UIView *)launcher_contentView{
    return objc_getAssociatedObject(self, @selector(launcher_contentView));
}

- (void)setLauncher_contentView:(UIView *)launcher_contentView{
    objc_setAssociatedObject(self, @selector(launcher_contentView), launcher_contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)launcher_currentIndex {
    return [objc_getAssociatedObject(self, @selector(launcher_currentIndex)) integerValue];
}

- (void)setLauncher_currentIndex:(NSInteger)launcher_currentIndex {
    objc_setAssociatedObject(self, @selector(launcher_currentIndex), @(launcher_currentIndex), OBJC_ASSOCIATION_ASSIGN);
}

- (UIView *)launcher_customView{
    return objc_getAssociatedObject(self, @selector(launcher_customView));
}

- (void)setLauncher_customView:(UIView *)launcher_customView{
    objc_setAssociatedObject(self, @selector(launcher_customView), launcher_customView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)launcher_containerView{
    UIView *containerView = [self view];
    if ([[self launcher_delegate] respondsToSelector:@selector(containerViewForLauncherInViewController:)]) {
        containerView = [[self launcher_delegate] containerViewForLauncherInViewController:self];
    }
    return containerView;
}

#pragma mark - private

- (UIView *)_launcher_loadContentView{
    
    UIView *contentView = [UIView new];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(launcher_didTapLauncherContentView:)];
    [contentView addGestureRecognizer:tapGestureRecognizer];
    
    UIView *containerView = [self launcher_containerView];
    contentView.frame = [containerView bounds];
    [containerView addSubview:contentView];
    
    return contentView;
}

- (UIView *)_launcher_loadCustomViewAniamted:(BOOL)animated atIndex:(NSUInteger)index{
    UIView *customView = nil;
    if ([[self launcher_delegate] respondsToSelector:@selector(viewController:customViewAtIndex:)]) {
        customView = [[self launcher_delegate] viewController:self customViewAtIndex:index];
    }
    if (customView) {
        CGPoint offset = CGPointZero;
        if ([[self launcher_delegate] respondsToSelector:@selector(viewController:offsetOfCustomViewAtIndex:)]) {
            offset = [[self launcher_delegate] viewController:self offsetOfCustomViewAtIndex:[self launcher_currentIndex]];
        }
        UIView *contentView = [self launcher_contentView];
        CGSize size = [contentView bounds].size;
        
        [contentView addSubview:customView];
        if ([customView translatesAutoresizingMaskIntoConstraints]) {
            customView.frame = CGRectMake(offset.x, offset.y, size.width - offset.x, size.height - offset.y);
        } else {
            [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[customView]|", offset.x] options:0 metrics:nil views:NSDictionaryOfVariableBindings(customView)]];
            [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%f-[customView]|", offset.y] options:0 metrics:nil views:NSDictionaryOfVariableBindings(customView)]];
        };
    }
    return customView;
}
- (void)_launcher_dismissAnimated:(BOOL)animated completion:(void (^)())completion{
    void (^animationCompletion)() = ^{
        [[self launcher_contentView] removeFromSuperview];
        self.launcher_contentView = nil;
        if (completion) {
            completion();
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.launcher_contentView.alpha = 0;
        } completion:^(BOOL finished) {
            animationCompletion();
        }];
    } else {
        animationCompletion();
    }
    if ([self launcher_delegate] && [[self launcher_delegate] respondsToSelector:@selector(launchViewDidDismissInViewController:)]) {
        [[self launcher_delegate] launchViewDidDismissInViewController:self];
    }
}

- (void)_launcher_exchangCustomView:(UIView *)customView originCustomView:(UIView *)originCustomView{
    CAAnimation *moveInAnimation = nil;
    CAAnimation *moveOutAnimation = nil;
    if (customView && [[self launcher_delegate] respondsToSelector:@selector(viewControler:animationForMovingInView:)]) {
        moveInAnimation = [[self launcher_delegate] viewControler:self animationForMovingInView:customView];
    }
    if (originCustomView && [[self launcher_delegate] respondsToSelector:@selector(viewControler:animationForMovingOutView:)]) {
        moveOutAnimation = [[self launcher_delegate] viewControler:self animationForMovingOutView:originCustomView];
    }
    
    if (!moveInAnimation) moveInAnimation = [self _launcher_defaultAnimation:YES];
    if (!moveOutAnimation) moveOutAnimation = [self _launcher_defaultAnimation:NO];
    
    if (customView) {
        [[customView layer] addAnimation:moveInAnimation forKey:nil];
    }
    if (originCustomView) {
        [[originCustomView layer] addAnimation:moveOutAnimation forKey:nil];
        [originCustomView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:[moveOutAnimation duration]];
    }
}

- (void)_launcher_updateContentSize{
    self.launcher_contentView.frame = [[self launcher_containerView] bounds];
}

- (CAAnimation *)_launcher_defaultAnimation:(BOOL)movingIn{
    CABasicAnimation *animation =[CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(!movingIn);
    animation.toValue = @(movingIn);
    animation.duration = .25f;
    return animation;
}

#pragma mark - actions

- (void)launcher_didTapLauncherContentView:(UITapGestureRecognizer *)tapGestureRecognizer {
    BOOL shouldTapLaucherContentView = YES;
    if ([[self launcher_delegate] respondsToSelector:@selector(shouldAllowTapLaunchViewInViewController:)]) {
        shouldTapLaucherContentView = [[self launcher_delegate] shouldAllowTapLaunchViewInViewController:self];
    }
    if (shouldTapLaucherContentView) {
        if ([[self launcher_delegate] respondsToSelector:@selector(launchViewDidTapInViewController:)]){
            [[self launcher_delegate] launchViewDidTapInViewController:self];
        }
        [self launcher_next];
    }
}

#pragma mark - public

- (void)laucherlauncher_dismissAnimated:(BOOL)animated completion:(void (^)())completion{
    [self launcher_dismissAnimated:animated completion:completion];
}

- (void)launcher_reload {
    
    if ([[self launcher_delegate] respondsToSelector:@selector(shouldLoadAgainBeforeLauncherFinishedInViewController:)] &&
        [[self launcher_delegate] shouldLoadAgainBeforeLauncherFinishedInViewController:self]) {
        [self launcher_reloadAgain];
    }
}

- (void)launcher_reloadAgain {
    if (self.launcher_delegate == nil) {
        return;
    }

    if ([[self launcher_delegate] respondsToSelector:@selector(shouldDisplayLaunchViewInViewController:)] &&
        ![[self launcher_delegate] shouldDisplayLaunchViewInViewController:self]) {
        return;
    }
    
    NSUInteger numberOfItems = [[self launcher_delegate] numberOfItemsForLauncherInViewController:self];
    if (!numberOfItems) {
        return;
    }
    if (![self launcher_contentView]) {
        self.launcher_contentView = [self _launcher_loadContentView];
    }
    
    if (![self launcher_customView]) {
        self.launcher_customView = [self _launcher_loadCustomViewAniamted:YES atIndex:[self launcher_currentIndex]];
    }
}

- (void)launcher_previous {
    if ([self launcher_currentIndex] - 1 < 0) {
        return;
    }
    UIView *customView = [self _launcher_loadCustomViewAniamted:YES atIndex:[self launcher_currentIndex] - 1];
    if (customView) {
        [self _launcher_exchangCustomView:customView originCustomView:[self launcher_customView]];
        
        self.launcher_customView = customView;
        self.launcher_currentIndex--;
    }
}

- (void)launcher_next {
    if (self.launcher_currentIndex < [[self launcher_delegate] numberOfItemsForLauncherInViewController:self] - 1) {
        UIView *customView = [self _launcher_loadCustomViewAniamted:YES atIndex:[self launcher_currentIndex] + 1];
        if (customView) {
            [self _launcher_exchangCustomView:customView originCustomView:[self launcher_customView]];
            
            self.launcher_customView = customView;
            self.launcher_currentIndex++;
        }
    } else {
        [self launcher_done];
    }
}

- (void)launcher_done {
    [self launcher_dismissAnimated:YES completion:^{
        self.launcher_currentIndex = 0;
    }];
}

- (void)launcher_dismissAnimated:(BOOL)animated completion:(void (^)())completion {
    [self _launcher_dismissAnimated:animated completion:^{
        self.launcher_currentIndex = 0;
        if (completion) {
            completion();
        }
    }];
}

@end
