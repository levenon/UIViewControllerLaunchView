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
        UIViewControllerLauncherMethodSwizzle(self, @selector(viewDidLoad), @selector(swizzle_viewDidLoad));
    });
}

- (void)swizzle_viewDidLoad{
    [self swizzle_viewDidLoad];
    
    if ([self launcher_delegate] &&
        [[self launcher_delegate] respondsToSelector:@selector(shouldLoadLauncherAfterViewDidLoadInViewController:)] &&
        [[self launcher_delegate] shouldLoadLauncherAfterViewDidLoadInViewController:self]) {
        [self launcher_reload];
    }
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

#pragma mark - private

- (UIView *)_loadContentView{
    
    UIView *contentView = [UIView new];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapLauncherContentView:)];
    [contentView addGestureRecognizer:tapGestureRecognizer];
    
    UIView *containerView = [self view];
    if ([[self launcher_delegate] respondsToSelector:@selector(containerViewForLauncherInViewController:)]) {
       containerView = [[self launcher_delegate] containerViewForLauncherInViewController:self];
    }
    contentView.frame = [containerView bounds];
    [containerView addSubview:contentView];
    
    return contentView;
}

- (UIView *)_loadCustomViewAniamted:(BOOL)animated atIndex:(NSUInteger)index{
    UIView *customView = nil;
    if ([[self launcher_delegate] respondsToSelector:@selector(viewController:customViewAtIndex:)]) {
        customView = [[self launcher_delegate] viewController:self customViewAtIndex:index];
    }
    if (customView) {
        CGPoint offset = CGPointZero;
        if ([[self launcher_delegate] respondsToSelector:@selector(viewController:offsetOfCustomViewAtIndex:)]) {
            offset = [[self launcher_delegate] viewController:self offsetOfCustomViewAtIndex:[self launcher_currentIndex]];
        }
        [[self launcher_contentView] addSubview:customView];
        CGSize size = [[self launcher_contentView] bounds].size;
        if (![[self launcher_customView] translatesAutoresizingMaskIntoConstraints]) {
            customView.frame = CGRectMake(customView.frame.origin.x, customView.frame.origin.y, size.width, size.height);
        } else {
            NSMutableArray *constraints = [NSMutableArray array];
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:customView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:size.width];
            [constraints addObject:constraint];
            constraint = [NSLayoutConstraint constraintWithItem:customView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:size.height];
            [constraints addObject:constraint];
            constraint = [NSLayoutConstraint constraintWithItem:customView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.launcher_contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:offset.x];
            [constraints addObject:constraint];
            constraint = [NSLayoutConstraint constraintWithItem:customView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.launcher_contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:offset.y];
            [constraints addObject:constraint];
            
            [customView addConstraints:constraints];
        };
    }
    return customView;
}
- (void)_dismissAnimated:(BOOL)animated completion:(void (^)())completion{
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.launcher_contentView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.launcher_contentView removeFromSuperview];
            self.launcher_contentView = nil;
            if (completion) {
                completion();
            }
        }];
    } else {
        [self.launcher_contentView removeFromSuperview];
        self.launcher_contentView = nil;
        if (completion) {
            completion();
        }
    }
    if (self.launcher_delegate && [self.launcher_delegate respondsToSelector:@selector(launchViewDidDismissInViewController:)]) {
        [self.launcher_delegate launchViewDidDismissInViewController:self];
    }
}

- (void)_exchangCustomView:(UIView *)customView originCustomView:(UIView *)originCustomView completion:(void (^)())completion{
    CAAnimation *moveInAnimation;
    CAAnimation *moveOutAnimation;
    if ([[self launcher_delegate] respondsToSelector:@selector(animationForMovingInLauncherInViewControler:)]) {
        moveInAnimation = [[self launcher_delegate] animationForMovingInLauncherInViewControler:self];
    }
    if ([[self launcher_delegate] respondsToSelector:@selector(animationForMovingOutLauncherInViewControler:)]) {
        moveOutAnimation = [[self launcher_delegate] animationForMovingOutLauncherInViewControler:self];
    }
    if (moveInAnimation || moveOutAnimation) {
        [customView.layer addAnimation:moveInAnimation forKey:nil];
        [originCustomView.layer addAnimation:moveOutAnimation forKey:nil];
        [originCustomView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:[moveOutAnimation duration]];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            customView.alpha = 1;
            originCustomView.alpha = 0;
        } completion:^(BOOL finished) {
            [originCustomView removeFromSuperview];
        }];
    }
}

#pragma mark - actions

- (void)didTapLauncherContentView:(UITapGestureRecognizer *)tapGestureRecognizer {
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

- (void)laucher_dismissAnimated:(BOOL)animated completion:(void (^)())completion{
    [self _dismissAnimated:animated completion:completion];
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
        self.launcher_contentView = [self _loadContentView];
    }
    
    if (![self launcher_customView]) {
        self.launcher_customView = [self _loadCustomViewAniamted:YES atIndex:[self launcher_currentIndex]];
    }
}

- (void)launcher_previous {
    if ([self launcher_currentIndex] - 1 < 0) {
        return;
    }
    UIView *customView = [self _loadCustomViewAniamted:YES atIndex:[self launcher_currentIndex] - 1];
    if (customView) {
        [self _exchangCustomView:customView originCustomView:[self launcher_customView] completion:nil];
        self.launcher_customView = customView;
        self.launcher_currentIndex--;
    }
}

- (void)launcher_next {
    if (self.launcher_currentIndex < [[self launcher_delegate] numberOfItemsForLauncherInViewController:self] - 1) {
        UIView *customView = [self _loadCustomViewAniamted:YES atIndex:[self launcher_currentIndex] + 1];
        if (customView) {
            [self _exchangCustomView:customView originCustomView:[self launcher_customView] completion:nil];
            self.launcher_customView = customView;
            self.launcher_currentIndex++;
        }
    } else {
        [self launcher_done];
    }
}

- (void)launcher_done {
    [self _dismissAnimated:YES completion:^{
        self.launcher_currentIndex = 0;
    }];
}

- (void)launcher_dismissAnimated:(BOOL)animated completion:(void (^)())completion {
    [self _dismissAnimated:animated completion:^{
        self.launcher_currentIndex = 0;
        if (completion) {
            completion();
        }
    }];
}

@end
