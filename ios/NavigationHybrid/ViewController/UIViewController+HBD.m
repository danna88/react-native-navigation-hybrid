//
//  UIViewController+HBD.m
//  NavigationHybrid
//
//  Created by Listen on 2018/1/22.
//  Copyright © 2018年 Listen. All rights reserved.
//

#import "UIViewController+HBD.h"
#import <objc/runtime.h>
#import "HBDNavigationController.h"
#import "HBDUtils.h"
#import "HBDModalViewController.h"

@implementation UIViewController (HBD)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        hbd_exchangeImplementations(class, @selector(dismissViewControllerAnimated:completion:), @selector(hbd_dismissViewControllerAnimated:completion:));
    });
}

- (void)hbd_dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    UIViewController *presented = self.presentedViewController;
    UIViewController *presenting = presented.presentingViewController;
    if (!presented) {
        presenting = self.presentingViewController;
        presented = presenting.presentedViewController;
    }
    
    [self hbd_dismissViewControllerAnimated:animated completion:^{
        if (completion) {
            completion();
        }
        [presenting didReceiveResultCode:presented.resultCode resultData:presented.resultData requestCode:presented.requestCode];
    }];
}

- (UIBarStyle)hbd_barStyle {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj) {
        return [obj integerValue];
    }
    return [UINavigationBar appearance].barStyle;
}

- (NSString *)sceneId {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (!obj) {
        obj = [[NSUUID UUID] UUIDString];
        objc_setAssociatedObject(self, @selector(sceneId), obj, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
     return obj;
}

- (void)setHbd_barStyle:(UIBarStyle)hbd_barStyle {
    objc_setAssociatedObject(self, @selector(hbd_barStyle), @(hbd_barStyle), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIColor *)hbd_barTintColor {
    if (self.hbd_barHidden) {
        return UIColor.clearColor;
    }
    
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj) {
        return obj;
    }
    
    if ([UINavigationBar appearance].barTintColor) {
        return [UINavigationBar appearance].barTintColor;
    }
    return [UINavigationBar appearance].barStyle == UIBarStyleDefault ? [UIColor whiteColor]: [UIColor blackColor];
}

- (void)setHbd_barTintColor:(UIColor *)tintColor {
    objc_setAssociatedObject(self, @selector(hbd_barTintColor), tintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)hbd_tintColor {
    id obj = objc_getAssociatedObject(self, _cmd);
    UIColor *color = obj ?: [UINavigationBar appearance].tintColor;
    return color;
}

- (void)setHbd_tintColor:(UIColor *)tintColor {
    objc_setAssociatedObject(self, @selector(hbd_tintColor), tintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)hbd_titleTextAttributes {
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ?: [UINavigationBar appearance].titleTextAttributes;
}

- (void)setHbd_titleTextAttributes:(NSDictionary *)attributes {
    objc_setAssociatedObject(self, @selector(hbd_titleTextAttributes), attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (float)hbd_barAlpha {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (self.hbd_barHidden) {
        return 0;
    }
    return obj ? [obj floatValue] : 1.0f;
}

- (void)setHbd_barAlpha:(float)alpha {
    objc_setAssociatedObject(self, @selector(hbd_barAlpha), @(alpha), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)hbd_barHidden {
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ? [obj boolValue] : NO;
}

- (void)setHbd_barHidden:(BOOL)hidden {
    if (hidden) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[UIView new]];
        self.navigationItem.titleView = [UIView new];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.titleView = nil;
    }
    objc_setAssociatedObject(self, @selector(hbd_barHidden), @(hidden), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (float)hbd_barShadowAlpha {
    return  self.hbd_barShadowHidden ? 0 : self.hbd_barAlpha;
}

- (BOOL)hbd_barShadowHidden {
    id obj = objc_getAssociatedObject(self, _cmd);
    return  self.hbd_barHidden || obj ? [obj boolValue] : NO;
}

- (void)setHbd_barShadowHidden:(BOOL)hidden {
    objc_setAssociatedObject(self, @selector(hbd_barShadowHidden), @(hidden), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)hbd_backInteractive {
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ? [obj boolValue] : YES;
}

-(void)setHbd_backInteractive:(BOOL)interactive {
    objc_setAssociatedObject(self, @selector(hbd_backInteractive), @(interactive), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)hbd_swipeBackEnabled {
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ? [obj boolValue] : YES;
}

- (void)setHbd_swipeBackEnabled:(BOOL)enabled {
     objc_setAssociatedObject(self, @selector(hbd_swipeBackEnabled), @(enabled), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)hbd_extendedLayoutIncludesTopBar {
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ? [obj boolValue] : NO;
}

- (void)setHbd_extendedLayoutIncludesTopBar:(BOOL)includesTopBar {
     objc_setAssociatedObject(self, @selector(hbd_extendedLayoutIncludesTopBar), @(includesTopBar), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)hbd_setNeedsUpdateNavigationBar {
    if (self.navigationController && [self.navigationController isKindOfClass:[HBDNavigationController class]]) {
        HBDNavigationController *nav = (HBDNavigationController *)self.navigationController;
        [nav updateNavigationBarForViewController:self];
    }
}

-(void)hbd_setNeedsUpdateNavigationBarAlpha {
    if (self.navigationController && [self.navigationController isKindOfClass:[HBDNavigationController class]]) {
        HBDNavigationController *nav = (HBDNavigationController *)self.navigationController;
        [nav updateNavigationBarAlphaForViewController:self];
    }
}

- (void)hbd_setNeedsUpdateNavigationBarColor {
    if (self.navigationController && [self.navigationController isKindOfClass:[HBDNavigationController class]]) {
        HBDNavigationController *nav = (HBDNavigationController *)self.navigationController;
        [nav updateNavigationBarColorForViewController:self];
    }
}

- (void)hbd_setNeedsUpdateNavigationBarShadowImageAlpha {
    if (self.navigationController && [self.navigationController isKindOfClass:[HBDNavigationController class]]) {
        HBDNavigationController *nav = (HBDNavigationController *)self.navigationController;
        [nav updateNavigationBarShadowImageAlphaForViewController:self];
    }
}

- (void)setResultCode:(NSInteger)resultCode {
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        objc_setAssociatedObject(presenting.presentedViewController, @selector(resultCode),@(resultCode), OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    objc_setAssociatedObject(self, @selector(resultCode),@(resultCode), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)resultCode {
    NSNumber *code = objc_getAssociatedObject(self, _cmd);
    return [code integerValue];
}

- (void)setResultData:(NSDictionary *)data {
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        objc_setAssociatedObject(presenting.presentedViewController, @selector(resultData), data, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    objc_setAssociatedObject(self, @selector(resultData), data, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)resultData {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRequestCode:(NSInteger)requestCode {
    objc_setAssociatedObject(self, @selector(requestCode), @(requestCode), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)requestCode {
    NSNumber *code = objc_getAssociatedObject(self, _cmd);
    return [code integerValue];
}

- (void)setResultCode:(NSInteger)resultCode resultData:(NSDictionary *)data {
    self.resultCode = resultCode;
    self.resultData = data;
}

- (void)didReceiveResultCode:(NSInteger)resultCode resultData:(NSDictionary *)data requestCode:(NSInteger)requestCode {
    if ([self isKindOfClass:[UITabBarController class]]) {
        UIViewController *child = ((UITabBarController *)self).selectedViewController;
        [child didReceiveResultCode:resultCode resultData:data requestCode:requestCode];
    } else if ([self isKindOfClass:[UINavigationController class]]) {
        UIViewController *child = ((UINavigationController *)self).topViewController;
        [child didReceiveResultCode:resultCode resultData:data requestCode:requestCode];
    } else if ([self isKindOfClass:[HBDDrawerController class]]) {
        UIViewController *child = ((HBDDrawerController *)self).contentController;
        [child didReceiveResultCode:resultCode resultData:data requestCode:requestCode];
    } else {
        NSArray *children = self.childViewControllers;
        if (children) {
            for (UIViewController *vc in children) {
                [vc didReceiveResultCode:resultCode resultData:data requestCode:requestCode];
            }
        }
    }
}

- (HBDDrawerController *)drawerController {
    UIViewController *vc = self;
    
    if ([vc isKindOfClass:[HBDDrawerController class]]) {
        return (HBDDrawerController *)vc;
    }
    
    UIViewController *parent = self.parentViewController;
    if (parent) {
        return [parent drawerController];
    }
    
    return nil;
}

- (void)hbd_updateTabBarItem:(NSDictionary *)options {
    NSDictionary *unselectedIcon = options[@"unselectedIcon"];
    NSDictionary *icon = options[@"icon"];
    UITabBarItem *tabBarItem = nil;
    if (unselectedIcon) {
        UIImage *selectedImage = [[HBDUtils UIImage:icon] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIImage *image = [[HBDUtils UIImage:unselectedIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem = [[UITabBarItem alloc] initWithTitle:self.tabBarItem.title image:image selectedImage:selectedImage];
    } else {
        tabBarItem = [[UITabBarItem alloc] initWithTitle:self.tabBarItem.title image:[HBDUtils UIImage:icon] selectedImage:nil];
    }
    tabBarItem.badgeValue = self.tabBarItem.badgeValue;
    self.tabBarItem = tabBarItem;
}

- (NSString *)hbd_mode {
    if ([self.view.window isKindOfClass:[HBDModalWindow class]]) {
        return @"modal";
    } else if (self.presentingViewController != nil) {
        return @"present";
    } else {
        return @"normal";
    }
}

@end

