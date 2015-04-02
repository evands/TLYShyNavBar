//
//  TLYShyViewController.m
//  TLYShyNavBarDemo
//
//  Created by Mazyad Alabduljaleel on 6/14/14.
//  Copyright (c) 2014 Telly, Inc. All rights reserved.
//

#import "TLYShyViewController.h"
#import "TLYStatusBarHeight.h"

const CGFloat contractionVelocity = 300.f;

@interface TLYShyViewController ()

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic) CGPoint expandedCenterValue;
@property (nonatomic) CGFloat contractionAmountValue;

@property (nonatomic) CGPoint contractedCenterValue;

@property (nonatomic, getter = isContracted) BOOL contracted;
@property (nonatomic, getter = isExpanded) BOOL expanded;
@property (nonatomic, copy) void(^tapGestureBlock)(void);

@end

@implementation TLYShyViewController

#pragma mark - Properties

// convenience
- (CGPoint)expandedCenterValue
{
    return self.expandedCenter(self.view);
}

- (CGFloat)contractionAmountValue
{
    return self.contractionAmount(self.view);
}

- (CGPoint)contractedCenterValue
{
    return CGPointMake(self.expandedCenterValue.x, self.expandedCenterValue.y - self.contractionAmountValue);
}

- (BOOL)isContracted
{
    return fabs(self.view.center.y - self.contractedCenterValue.y) < FLT_EPSILON;
}

- (BOOL)isExpanded
{
    return fabs(self.view.center.y - self.expandedCenterValue.y) < FLT_EPSILON;
}

- (CGFloat)totalHeight
{
    return self.child.totalHeight + (self.expandedCenterValue.y - self.contractedCenterValue.y);
}

#pragma mark - Private methods

// This method is courtesy of GTScrollNavigationBar
// https://github.com/luugiathuy/GTScrollNavigationBar
- (void)_updateSubviewsToAlpha:(CGFloat)alpha
{
    for (UIView* view in self.view.subviews)
    {
        if (view == self.titleLabel) {
            view.alpha = (1.f - alpha) > 0.5f ? 1.5f - 2.f * alpha : 0; //(0.5f - (alpha - 0.5f)*2)
        } else {
            bool isBackgroundView = view == self.view.subviews[0];
            bool isViewHidden = view.hidden || view.alpha < FLT_EPSILON;

            if (!isBackgroundView && !isViewHidden)
            {
                view.alpha = alpha;
            }
        }
    }
}

- (void)dealloc {
    [self.titleLabel removeFromSuperview];
}

#pragma mark - Public methods

- (void)setAlphaFadeEnabled:(BOOL)alphaFadeEnabled
{
    _alphaFadeEnabled = alphaFadeEnabled;
    
    if (!alphaFadeEnabled)
    {
        [self _updateSubviewsToAlpha:1.f];
    }
}

- (void)setChildViewHidden:(BOOL)hidden {
    if (self.child.view.hidden != hidden) {
        self.child.view.hidden = hidden;

        if ([self.delegate respondsToSelector:@selector(shyViewController:didChangeChildViewHidden:)]) {
            [self.delegate shyViewController:self didChangeChildViewHidden:hidden];
        }
    }
}

- (void)_sendToDelegateChildVisiblePercent {
    if (self.child) {
        CGFloat minOffsetValue = self.view.frame.size.height - self.child.view.frame.size.height;
        CGFloat offset = (self.child.view.frame.origin.y - minOffsetValue - [TLYStatusBarHeight statusBarHeight]);

        if ([self.delegate respondsToSelector:@selector(shyViewController:childIsVisibleInPercent:changeAnimated:withTime:)]) {
            [self.delegate shyViewController:self
                     childIsVisibleInPercent:offset/self.child.view.frame.size.height
                              changeAnimated:NO
                                    withTime:0];
        }
    }
}

- (CGFloat)updateYOffset:(CGFloat)deltaY
{
    if (self.child && deltaY < 0)
    {
        deltaY = [self.child updateYOffset:deltaY];
        [self setChildViewHidden:(deltaY) < 0];
    }
    
    CGFloat newYOffset = self.view.center.y + deltaY;
    CGFloat newYCenter = MAX(MIN(self.expandedCenterValue.y, newYOffset), self.contractedCenterValue.y);
    
    self.view.center = CGPointMake(self.expandedCenterValue.x, newYCenter);
    
    if (self.hidesSubviews)
    {
        CGFloat newAlpha = 1.f - (self.expandedCenterValue.y - self.view.center.y) / self.contractionAmountValue;
        newAlpha = MIN(MAX(FLT_EPSILON, newAlpha), 1.f);
        
        if (self.alphaFadeEnabled)
        {
            [self _updateSubviewsToAlpha:newAlpha];
        }
    }
    
    CGFloat residual = newYOffset - newYCenter;
    
    if (self.child && deltaY > 0 && residual > 0)
    {
        residual = [self.child updateYOffset:residual];
        BOOL isHidden = (residual - (newYOffset - newYCenter)) > FLT_EPSILON;
        [self setChildViewHidden:isHidden];
    }

    [self _sendToDelegateChildVisiblePercent];
    return residual;
}

- (CGFloat)snap:(BOOL)contract
{
    /* "The Facebook" UX dictates that:
     *
     *      1 - When you contract:
     *          A - contract beyond the extension view -> contract the whole thing
     *          B - contract within the extension view -> expand the extension back
     *
     *      2 - When you expand:
     *          A - expand beyond the navbar -> expand the whole thing
     *          B - expand within the navbar -> contract the navbar back
     */
    
    __block CGFloat deltaY;
    __block BOOL didExpand = NO;
    NSTimeInterval animationTime = 0.2;

    [UIView animateWithDuration:animationTime animations:^
    {
        if ((contract && self.child.isContracted) || (!contract && !self.isExpanded))
        {
            deltaY = [self contract];
        }
        else
        {
            deltaY = [self.child expand];
            didExpand = YES;
        }
    }];

    if (didExpand == YES
        && [self.delegate respondsToSelector:@selector(shyViewController:childIsVisibleInPercent:changeAnimated:withTime:)]) {

        [self.delegate shyViewController:self
                 childIsVisibleInPercent:1.0f
                          changeAnimated:YES
                                withTime:animationTime];
    }

    return deltaY;
}

- (CGFloat)expand
{
    self.view.hidden = NO;
    
    if (self.hidesSubviews && self.alphaFadeEnabled)
    {
        [self _updateSubviewsToAlpha:1.f];
    }
    
    CGFloat amountToMove = self.expandedCenterValue.y - self.view.center.y;

    self.view.center = self.expandedCenterValue;
    [self.child expand];
    
    return amountToMove;
}

- (CGFloat)contract
{
    CGFloat amountToMove = self.contractedCenterValue.y - self.view.center.y;

    self.view.center = self.contractedCenterValue;
    [self.child contract];
    
    return amountToMove;
}

- (CGFloat)titleLabelHeight {
    return 15.0f;
}

- (void)showAndConfigureTitleLabelWithText:(NSString *)text fontName:(NSString *)fontName tapGestureBlock:(void (^)(void))tapGestureBlock {
    if (self.titleLabel == nil) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f,
                                                                    self.view.bounds.size.height - self.titleLabelHeight - 1.f,
                                                                    self.view.bounds.size.width,
                                                                    self.titleLabelHeight)];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.alpha = 0.f;
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        self.titleLabel.userInteractionEnabled = YES;
        [self.view addSubview:self.titleLabel];

        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_navBarGestureDidRecognizeTap:)];
        self.tapGestureBlock = tapGestureBlock;
        [self.titleLabel addGestureRecognizer:recognizer];
    }
    self.titleLabel.text = text;
    self.titleLabel.font = [UIFont fontWithName:fontName size:12.0f];
}

- (void)hideTitleLabel {
    [self.titleLabel removeFromSuperview];
    self.titleLabel = nil;
}

- (void)_navBarGestureDidRecognizeTap:(UIGestureRecognizer *)sender {
    if (self.tapGestureBlock) {
        self.tapGestureBlock();
    }
}

@end
