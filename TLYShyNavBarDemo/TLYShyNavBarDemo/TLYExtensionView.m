//
//  TLYExtensionView.m
//  TLYShyNavBarDemo
//
//  Created by Remigiusz Herba on 20/03/15.
//  Copyright (c) 2015 Telly, Inc. All rights reserved.
//

#import "TLYExtensionView.h"

@implementation TLYExtensionView

@synthesize extensionViewTitle = _extensionViewTitle;
@synthesize needsUpdate = _needsUpdate;

- (NSString *)extensionViewTitle {
    return @"WTFox Say";
}

- (NSString *)fontName {
    return @"HelveticaNeue";
}

@end
