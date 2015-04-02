//
//  TLYStatusBarHeight.m
//  TLYShyNavBarDemo
//
//  Created by Remigiusz Herba on 02/04/15.
//  Copyright (c) 2015 Telly, Inc. All rights reserved.
//

#import "TLYStatusBarHeight.h"

@implementation TLYStatusBarHeight

+ (CGFloat)statusBarHeight {
    if ([UIApplication sharedApplication].statusBarHidden)
    {
        return 0.f;
    }

    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    return MIN(MIN(statusBarSize.width, statusBarSize.height), 20.0f);
}

@end
