//
//  HBDNavigationController.m
//  NavigationHybrid
//
//  Created by Listen on 2017/12/16.
//  Copyright © 2018年 Listen. All rights reserved.
//

#import "HBDNavigationController.h"
#import "HBDViewController.h"
#import "UIViewController+HBD.h"
#import "HBDNavigationBar.h"
#import "HBDReactBridgeManager.h"
#import "HBDUtils.h"
#import "HBDGarden.h"
#import "HBDReactViewController.h"
#import "HBDRootView.h"

@interface HBDNavigationController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, readonly) HBDNavigationBar *navigationBar;
@property (nonatomic, strong) UIVisualEffectView *fromFakeBar;
@property (nonatomic, strong) UIVisualEffectView *toFakeBar;
@property (nonatomic, strong) UIImageView *fromFakeShadow;
@property (nonatomic, strong) UIImageView *toFakeShadow;
@property (nonatomic, weak) UIViewController *poppingViewController;
@property (nonatomic, assign) BOOL transitional;

@end

@implementation HBDNavigationController

@dynamic navigationBar;

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithNavigationBarClass:[HBDNavigationBar class] toolbarClass:nil]) {
        if ([rootViewController isKindOfClass:[HBDViewController class]]) {
            HBDViewController *root = (HBDViewController *)rootViewController;
            self.tabBarItem = root.tabBarItem;
            root.tabBarItem = nil;
            NSDictionary *tabItem = root.options[@"tabItem"];
            if (tabItem) {
                self.hidesBottomBarWhenPushed = [tabItem[@"hideTabBarWhenPush"] boolValue];
            }
        }
        self.viewControllers = @[ rootViewController ];
    }
    return self;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.definesPresentationContext = NO;
    self.interactivePopGestureRecognizer.delegate = self;
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
    self.delegate = self;
    [self.navigationBar setTranslucent:YES];
    [self.navigationBar setShadowImage:[UINavigationBar appearance].shadowImage];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // 修复一个神奇的 BUG https://github.com/listenzz/HBDNavigationBar/issues/29
    self.topViewController.view.frame = self.topViewController.view.frame;
    id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
    if (coordinator) {
        // 解决 ios 11 手势反弹的问题
        UIViewController *from = [coordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
        if (from == self.poppingViewController && !self.transitional) {
            [self updateNavigationBarForViewController:from];
        }
    } else {
        // 再修复一个神奇的 BUG: https://github.com/listenzz/HBDNavigationBar/issues/31
        [self updateNavigationBarForViewController:self.topViewController];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.viewControllers.count > 1) {
        if ([self.topViewController isKindOfClass:[HBDReactViewController class]]) {
            HBDReactViewController *vc = (HBDReactViewController *)self.topViewController;
            [vc.rootView cancelTouches];
        }
        return self.topViewController.hbd_backInteractive && self.topViewController.hbd_swipeBackEnabled;
    }
    return NO;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    if (self.viewControllers.count > 1 && self.topViewController.navigationItem == item) {
        if (!self.topViewController.hbd_backInteractive) {
            [self resetSubviewsInNavBar:self.navigationBar];
            return NO;
        }
    }
    return [super navigationBar:navigationBar shouldPopItem:item];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.transitional = YES;
    self.navigationBar.titleTextAttributes = viewController.hbd_titleTextAttributes;
    self.navigationBar.barStyle = viewController.hbd_barStyle;
    
    id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
    if (coordinator) {
        [self showViewController:viewController withCoordinator:coordinator];
    } else {
        if (!animated && self.childViewControllers.count > 1) {
            UIViewController *lastButOne = self.childViewControllers[self.childViewControllers.count - 2];
            if ([self shouldShowFakeBarFrom:lastButOne to:viewController viewController:viewController]) {
                [self showFakeBarFrom:lastButOne to:viewController];
                return;
            }
        }
        [self updateNavigationBarForViewController:viewController];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.transitional = NO;
    if (!animated) {
        [self updateNavigationBarForViewController:viewController];
        [self clearFake];
    }
    if (self.poppingViewController && [self.poppingViewController isKindOfClass:[HBDViewController class]]) {
        [viewController didReceiveResultCode:self.poppingViewController.resultCode resultData:self.poppingViewController.resultData requestCode:0];
    }
    self.poppingViewController = nil;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self shouldBetterTransitionWithViewController:viewController]) {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromRight;
        [self.view.layer addAnimation:transition forKey:nil];
        [super pushViewController:viewController animated:NO];
    } else {
        [super pushViewController:viewController animated:animated];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *vc;
    self.poppingViewController = self.topViewController;
    if ([self shouldBetterTransitionWithViewController:self.topViewController]) {
        [self prepareForPopTransitionAnimated:animated];
        vc = [super popViewControllerAnimated:NO];
    } else {
        vc = [super popViewControllerAnimated:animated];
    }
    self.navigationBar.barStyle = self.topViewController.hbd_barStyle;
    self.navigationBar.titleTextAttributes = self.topViewController.hbd_titleTextAttributes;
    return vc;
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.poppingViewController = self.topViewController;
    NSArray *array;
    if ([self shouldBetterTransitionWithViewController:self.topViewController]) {
        [self prepareForPopTransitionAnimated:animated];
        array = [super popToViewController:viewController animated:NO];
    } else {
        array = [super popToViewController:viewController animated:animated];
    }
    
    self.navigationBar.barStyle = self.topViewController.hbd_barStyle;
    self.navigationBar.titleTextAttributes = self.topViewController.hbd_titleTextAttributes;
    return array;
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    self.poppingViewController = self.topViewController;
    NSArray *array;
    if ([self shouldBetterTransitionWithViewController:self.topViewController]) {
        [self prepareForPopTransitionAnimated:animated];
        array = [super popToRootViewControllerAnimated:NO];
    } else {
        array = [super popToRootViewControllerAnimated:animated];
    }
    self.navigationBar.barStyle = self.topViewController.hbd_barStyle;
    self.navigationBar.titleTextAttributes = self.topViewController.hbd_titleTextAttributes;
    return array;
}

- (void)handlePopGesture:(UIScreenEdgePanGestureRecognizer *)recognizer {
    id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
    UIViewController *from = [coordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *to = [coordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        self.navigationBar.tintColor = blendColor(from.hbd_tintColor, to.hbd_tintColor, coordinator.percentComplete);
    }
}

- (void)resetSubviewsInNavBar:(UINavigationBar *)navBar {
    if (@available(iOS 11, *)) {
    } else {
        // Workaround for >= iOS7.1. Thanks to @boliva - http://stackoverflow.com/posts/comments/34452906
        [navBar.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
            if (subview.alpha < 1.0) {
                [UIView animateWithDuration:.25 animations:^{
                    subview.alpha = 1.0;
                }];
            }
        }];
    }
}

- (void)resetButtonLabelInNavBar:(UINavigationBar *)navBar {
    if (@available(iOS 12.0, *)) {
        for (UIView *view in navBar.subviews) {
            NSString *viewName = [[[view classForCoder] description] stringByReplacingOccurrencesOfString:@"_" withString:@""];
            if ([viewName isEqualToString:@"UINavigationBarContentView"]) {
                [self resetButtonLabelInView:view];
                break;
            }
        }
    }
}

- (void)resetButtonLabelInView:(UIView *)view {
    NSString *viewName = [[[view classForCoder] description] stringByReplacingOccurrencesOfString:@"_" withString:@""];
    if ([viewName isEqualToString:@"UIButtonLabel"]) {
        view.alpha = 1.0;
    } else if (view.subviews.count > 0) {
        for (UIView *sub in view.subviews) {
            [self resetButtonLabelInView:sub];
        }
    }
}

- (void)printSubViews:(UIView *)view prefix:(NSString *)prefix {
    NSString *viewName = [[[view classForCoder] description] stringByReplacingOccurrencesOfString:@"_" withString:@""];
    NSLog(@"%@%@", prefix, viewName);
    if (view.subviews.count > 0) {
        for (UIView *sub in view.subviews) {
            [self printSubViews:sub prefix:[NSString stringWithFormat:@"--%@", prefix]];
        }
    }
}

- (void)updateNavigationBarForViewController:(UIViewController *)vc {
    [self updateNavigationBarAlphaForViewController:vc];
    [self updateNavigationBarColorForViewController:vc];
    [self updateNavigationBarShadowImageAlphaForViewController:vc];
    [self updateNavigationBarAnimatedForViewController:vc];
}

- (void)updateNavigationBarAnimatedForViewController:(UIViewController *)vc {
    self.navigationBar.barStyle = vc.hbd_barStyle;
    self.navigationBar.titleTextAttributes = vc.hbd_titleTextAttributes;
    self.navigationBar.tintColor = vc.hbd_tintColor;
}

- (void)updateNavigationBarAlphaForViewController:(UIViewController *)vc {
    self.navigationBar.fakeView.alpha = vc.hbd_barAlpha;
    self.navigationBar.shadowImageView.alpha = vc.hbd_barShadowAlpha;
}

- (void)updateNavigationBarColorForViewController:(UIViewController *)vc {
    self.navigationBar.barTintColor = vc.hbd_barTintColor;
}

- (void)updateNavigationBarShadowImageAlphaForViewController:(UIViewController *)vc {
    self.navigationBar.shadowImageView.alpha = vc.hbd_barShadowAlpha;
}

- (void)showViewController:(UIViewController * _Nonnull)viewController withCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    UIViewController *from = [coordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *to = [coordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // 修复一个系统 BUG https://github.com/listenzz/HBDNavigationBar/issues/35
    [self resetButtonLabelInNavBar:self.navigationBar];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        BOOL shouldFake = [self shouldShowFakeBarFrom:from to:to viewController:viewController];
        if (shouldFake) {
            [self showViewControllerAlongsideTransition:viewController from:from to:to interactive:context.interactive];
        } else {
            [self showViewControllerAlongsideTransition:viewController interactive:context.interactive];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        self.transitional = NO;
        if (context.isCancelled) {
            [self updateNavigationBarForViewController:from];
        } else {
            // 当 present 时 to 不等于 viewController
            [self updateNavigationBarForViewController:viewController];
        }
        if (to == viewController) {
            [self clearFake];
        }
    }];
    
    if (coordinator.interactive) {
        if (@available(iOS 10.0, *)) {
            [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                if (context.isCancelled) {
                    [self updateNavigationBarAnimatedForViewController:from];
                } else {
                    [self updateNavigationBarAnimatedForViewController:viewController];
                }
            }];
        } else {
            [coordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                if (context.isCancelled) {
                    [self updateNavigationBarAnimatedForViewController:from];
                } else {
                    [self updateNavigationBarAnimatedForViewController:viewController];
                }
            }];
        }
    }
}

- (void)showViewControllerAlongsideTransition:(UIViewController * _Nonnull)viewController interactive:(BOOL)interactive {
    self.navigationBar.titleTextAttributes = viewController.hbd_titleTextAttributes;
    self.navigationBar.barStyle = viewController.hbd_barStyle;
    if (!interactive) {
        self.navigationBar.tintColor = viewController.hbd_tintColor;
    }
    
    [self updateNavigationBarAlphaForViewController:viewController];
    [self updateNavigationBarColorForViewController:viewController];
    [self updateNavigationBarShadowImageAlphaForViewController:viewController];
}

- (void)showViewControllerAlongsideTransition:(UIViewController *)viewController from:(UIViewController *)from to:(UIViewController * _Nonnull)to interactive:(BOOL)interactive {
    // 标题样式，按钮颜色，barStyle
    self.navigationBar.titleTextAttributes = viewController.hbd_titleTextAttributes;
    self.navigationBar.barStyle = viewController.hbd_barStyle;
    if (!interactive) {
        self.navigationBar.tintColor = viewController.hbd_tintColor;
    }
    // 背景透明度，背景颜色，阴影透明度
    [self showFakeBarFrom:from to:to];
}

- (void)showFakeBarFrom:(UIViewController *)from to:(UIViewController * _Nonnull)to {
    [UIView setAnimationsEnabled:NO];
    self.navigationBar.fakeView.alpha = 0;
    self.navigationBar.shadowImageView.alpha = 0;
    [self showFakeBarFrom:from];
    [self showFakeBarTo:to];
    [UIView setAnimationsEnabled:YES];
}

- (void)showFakeBarFrom:(UIViewController *)from {
    self.fromFakeBar.subviews.lastObject.backgroundColor = from.hbd_barTintColor;
    self.fromFakeBar.alpha = from.hbd_barAlpha == 0 ? 0.01 : from.hbd_barAlpha;
    if (from.hbd_barAlpha == 0) {
        self.fromFakeBar.subviews.lastObject.alpha = 0.01;
    }
    self.fromFakeBar.frame = [self fakeBarFrameForViewController:from];
    [from.view addSubview:self.fromFakeBar];
    self.fromFakeShadow.alpha = from.hbd_barShadowAlpha;
    self.fromFakeShadow.frame = [self fakeShadowFrameWithBarFrame:self.fromFakeBar.frame];
    [from.view addSubview:self.fromFakeShadow];
}

- (void)showFakeBarTo:(UIViewController * _Nonnull)to {
    self.toFakeBar.subviews.lastObject.backgroundColor = to.hbd_barTintColor;
    self.toFakeBar.alpha = to.hbd_barAlpha;
    self.toFakeBar.frame = [self fakeBarFrameForViewController:to];
    [to.view addSubview:self.toFakeBar];
    self.toFakeShadow.alpha = to.hbd_barShadowAlpha;
    self.toFakeShadow.frame = [self fakeShadowFrameWithBarFrame:self.toFakeBar.frame];
    [to.view addSubview:self.toFakeShadow];
}

- (BOOL)shouldShowFakeBarFrom:(UIViewController *)from to:(UIViewController *)to viewController:(UIViewController * _Nonnull)viewController {
    BOOL shouldFake = to == viewController && (![from.hbd_barTintColor.description  isEqual:to.hbd_barTintColor.description] || ABS(from.hbd_barAlpha - to.hbd_barAlpha) > 0.1);
    return shouldFake;
}

- (BOOL)shouldBetterTransitionWithViewController:(UIViewController *)vc {
    BOOL shouldBetter = NO;
    if ([vc isKindOfClass:[HBDViewController class]]) {
        HBDViewController *hbd = (HBDViewController *)vc;
        shouldBetter = [hbd.options[@"passThroughTouches"] boolValue];
    }
    return shouldBetter;
}

- (void)prepareForPopTransitionAnimated:(BOOL)animated {
    if (animated) {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromLeft;
        [self.view.layer addAnimation:transition forKey:nil];
    }
}

- (UIVisualEffectView *)fromFakeBar {
    if (!_fromFakeBar) {
        _fromFakeBar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    }
    return _fromFakeBar;
}

- (UIVisualEffectView *)toFakeBar {
    if (!_toFakeBar) {
        _toFakeBar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    }
    return _toFakeBar;
}

- (UIImageView *)fromFakeShadow {
    if (!_fromFakeShadow) {
        _fromFakeShadow = [[UIImageView alloc] initWithImage:self.navigationBar.shadowImageView.image];
        _fromFakeShadow.backgroundColor = self.navigationBar.shadowImageView.backgroundColor;
    }
    return _fromFakeShadow;
}

- (UIImageView *)toFakeShadow {
    if (!_toFakeShadow) {
        _toFakeShadow = [[UIImageView alloc] initWithImage:self.navigationBar.shadowImageView.image];
        _toFakeShadow.backgroundColor = self.navigationBar.shadowImageView.backgroundColor;
    }
    return _toFakeShadow;
}

- (void)clearFake {
    [self.fromFakeBar removeFromSuperview];
    [self.toFakeBar removeFromSuperview];
    [self.fromFakeShadow removeFromSuperview];
    [self.toFakeShadow removeFromSuperview];
    _fromFakeBar = nil;
    _toFakeBar = nil;
    _fromFakeShadow = nil;
    _toFakeShadow = nil;
}

- (CGRect)fakeBarFrameForViewController:(UIViewController *)vc {
    UIView *back = self.navigationBar.subviews[0];
    CGRect frame = [self.navigationBar convertRect:back.frame toView:vc.view];
    frame.origin.x = vc.view.frame.origin.x;
    //  解决根视图为scrollView的时候，Push不正常
    if ([vc.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollview = (UIScrollView *)vc.view;
        //  适配iPhoneX iPhoneXR
        NSArray *xrs =@[ @812, @896 ];
        BOOL isIPhoneX = [xrs containsObject:@([UIScreen mainScreen].bounds.size.height)];
        if (scrollview.contentOffset.y == 0) {
            frame.origin.y = -(isIPhoneX ? 88 : 64);
        }
    }
    return frame;
}

- (CGRect)fakeShadowFrameWithBarFrame:(CGRect)frame {
    return CGRectMake(frame.origin.x, frame.size.height + frame.origin.y, frame.size.width, 0.5);
}

UIColor* blendColor(UIColor *from, UIColor *to, float percent) {
    CGFloat fromRed = 0;
    CGFloat fromGreen = 0;
    CGFloat fromBlue = 0;
    CGFloat fromAlpha = 0;
    [from getRed:&fromRed green:&fromGreen blue:&fromBlue alpha:&fromAlpha];
    
    CGFloat toRed = 0;
    CGFloat toGreen = 0;
    CGFloat toBlue = 0;
    CGFloat toAlpha = 0;
    [to getRed:&toRed green:&toGreen blue:&toBlue alpha:&toAlpha];
    
    CGFloat newRed =  fromRed + (toRed - fromRed) * fminf(1, percent * 4) ;
    CGFloat newGreen = fromGreen + (toGreen - fromGreen) * fminf(1, percent * 4);
    CGFloat newBlue = fromBlue + (toBlue - fromBlue) * fminf(1, percent * 4);
    CGFloat newAlpha = fromAlpha + (toAlpha - fromAlpha) * fminf(1, percent * 4);
    return [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:newAlpha];
}

@end
