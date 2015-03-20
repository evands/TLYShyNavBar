//
//  TLYShyExtensionView.h
//  TLYShyNavBarDemo
//
//  Created by Remigiusz Herba on 20/03/15.
//  Copyright (c) 2015 Telly, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TLYShyExtensionView <NSObject>

@property (nonatomic, copy, readonly) NSString *extensionViewTitle;
@property (nonatomic, copy, readonly) NSString *fontName;

@end
