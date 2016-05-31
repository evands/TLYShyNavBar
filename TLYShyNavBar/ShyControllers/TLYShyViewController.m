//
//  TLYShyViewController.m
//  TLYShyNavBarDemo
//
//  Created by Mazyad Alabduljaleel on 6/14/14.
//  Copyright (c) 2014 Telly, Inc. All rights reserved.
//

#import "TLYShyViewController.h"
#import "TLYStatusBarHeight.h"

@implementation TLYShyViewController (AsParent)

- (CGFloat)maxYRelativeToView:(UIView *)superview
{
    CGPoint maxEdge = CGPointMake(0, CGRectGetHeight(self.view.bounds));
    CGPoint normalizedMaxEdge = [superview convertPoint:maxEdge fromView:self.view];
    
    return normalizedMaxEdge.y;
}

- (CGFloat)calculateTotalHeightRecursively
{
    return CGRectGetHeight(self.view.bounds) + [self.parent calculateTotalHeightRecursively];
}

@end


@interface TLYShyViewController ()

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) CGPoint expandedCenterValue;
@property (nonatomic, assign) CGFloat contractionAmountValue;

@property (nonatomic, assign) CGPoint contractedCenterValue;

@property (nonatomic, assign) BOOL contracted;
@property (nonatomic, assign) BOOL expanded;

@property (nonatomic, copy) void(^tapGestureBlock)(void);

@end

@implementation TLYShyViewController

#pragma mark - Properties

// convenience
- (CGPoint)expandedCenterValue
{
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds),
                                 CGRectGetMidY(self.view.bounds));
    
    center.y += [self.parent maxYRelativeToView:self.view.superview];
    
    return center;
}

- (CGFloat)contractionAmountValue
{
    CGFloat amount = self.sticky ? 0.f : CGRectGetHeight(self.view.bounds);
    if (self.contractionAmountModifier == nil) {
        return amount;
    } else {
        return amount + self.contractionAmountModifier();
    }
}

- (CGPoint)contractedCenterValue
{
    return CGPointMake(self.expandedCenterValue.x, self.expandedCenterValue.y - self.contractionAmountValue);
}

- (BOOL)contracted
{
    return fabs(self.view.center.y - self.contractedCenterValue.y) < FLT_EPSILON;
}

- (BOOL)expanded
{
    return fabs(self.view.center.y - self.expandedCenterValue.y) < FLT_EPSILON;
}

#pragma mark - Private methods

- (void)_onAlphaUpdate:(CGFloat)alpha
{
    if (self.sticky)
    {
        self.view.alpha = 1.f;
        [self _updateSubviewsAlpha:1.f];
        return;
    }
    
    switch (self.fadeBehavior) {
            
        case TLYShyNavBarFadeDisabled:
            self.view.alpha = 1.f;
            [self _updateSubviewsAlpha:1.f];
            break;
            
        case TLYShyNavBarFadeSubviews:
            self.view.alpha = 1.f;
            [self _updateSubviewsAlpha:alpha];
            break;
            
        case TLYShyNavBarFadeNavbar:
            self.view.alpha = alpha;
            [self _updateSubviewsAlpha:1.f];
            break;
    }
}

// This method is courtesy of GTScrollNavigationBar
// https://github.com/luugiathuy/GTScrollNavigationBar
- (void)_updateSubviewsAlpha:(CGFloat)alpha
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

- (void)_updateCenter:(CGPoint)newCenter
{
    CGPoint currentCenter = self.view.center;
    CGPoint deltaPoint = CGPointMake(newCenter.x - currentCenter.x,
                                     newCenter.y - currentCenter.y);
    
    [self offsetCenterBy:deltaPoint];
}

#pragma mark - Public methods

- (void)setFadeBehavior:(TLYShyNavBarFade)fadeBehavior
{
    _fadeBehavior = fadeBehavior;
    
    if (fadeBehavior == TLYShyNavBarFadeDisabled)
    {
        [self _onAlphaUpdate:1.f];
    }
}

- (void)offsetCenterBy:(CGPoint)deltaPoint
{
    self.view.center = CGPointMake(self.view.center.x + deltaPoint.x,
                                   self.view.center.y + deltaPoint.y);
    
    [self.child offsetCenterBy:deltaPoint];
}

- (void)setChildViewHidden:(BOOL)hidden {
    if (self.subShyController.view.hidden != hidden) {
        self.subShyController.view.hidden = hidden;
        
        [self _informDelegateChildIsVisibleInPercent:0.0f
                                            animated:NO
                               withAnimationDuration:0];
    }
}

- (void)_informDelegateAboutChildVisibility {
    if (self.child) {
        CGFloat minOffsetValue = self.view.frame.size.height - self.subShyController.view.frame.size.height;
        CGFloat offset = (self.subShyController.view.frame.origin.y - minOffsetValue - [TLYStatusBarHeight statusBarHeight]);
        
        [self _informDelegateChildIsVisibleInPercent:offset/self.subShyController.view.frame.size.height
                                            animated:NO
                               withAnimationDuration:0];
    }
}

- (void)_informDelegateChildIsVisibleInPercent:(CGFloat)percent animated:(BOOL)animated withAnimationDuration:(NSTimeInterval)duration {
    if ([self.delegate respondsToSelector:@selector(shyViewController:childIsVisibleInPercent:changeAnimated:withAnimationDuration:)]) {
        [self.delegate shyViewController:self
                 childIsVisibleInPercent:percent
                          changeAnimated:animated
                   withAnimationDuration:duration];
    }
}

- (CGFloat)updateYOffset:(CGFloat)deltaY
{    
    if (self.subShyController && deltaY < 0)
    {
        deltaY = [self.subShyController updateYOffset:deltaY];
    }
    
    CGFloat residual = deltaY;
    
    if (!self.sticky)
    {
        CGFloat newYOffset = self.view.center.y + deltaY;
        CGFloat newYCenter = MAX(MIN(self.expandedCenterValue.y, newYOffset), self.contractedCenterValue.y);
        
        [self _updateCenter:CGPointMake(self.expandedCenterValue.x, newYCenter)];
        
        CGFloat newAlpha = 1.f - (self.expandedCenterValue.y - self.view.center.y) / self.contractionAmountValue;
        newAlpha = MIN(MAX(FLT_EPSILON, newAlpha), 1.f);
        
        [self _onAlphaUpdate:newAlpha];
        
        residual = newYOffset - newYCenter;
        
        // QUICK FIX: Only the extensionView is hidden
        if (!self.subShyController)
        {
            self.view.hidden = residual < 0;
        }
    }
    
    if (self.subShyController && deltaY > 0 && residual > 0)
    {
        residual = [self.subShyController updateYOffset:residual];
    }
    
    [self _informDelegateAboutChildVisibility];
    
    return residual;
}

- (CGFloat)snap:(BOOL)contract
{
    return [self snap:contract completion:nil];
}

- (CGFloat)snap:(BOOL)contract completion:(void (^)())completion
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
        if ((contract && self.subShyController.contracted) || (!contract && !self.expanded))
        {
            deltaY = [self contract];
        }
        else
        {
            deltaY = [self.subShyController expand];
            didExpand = YES;
        }
    }
                     completion:^(BOOL finished)
    {
        if (completion && finished) {
            completion();
        }
    }];
    
    if (didExpand == YES) {
        [self _informDelegateChildIsVisibleInPercent:1.0f
                                            animated:YES
                               withAnimationDuration:animationTime];
    }
    
    return deltaY;
}

- (CGFloat)expand
{
    self.view.hidden = NO;
    
    [self _onAlphaUpdate:1.f];
    
    CGFloat amountToMove = self.expandedCenterValue.y - self.view.center.y;

    [self _updateCenter:self.expandedCenterValue];
    [self.subShyController expand];
    
    [self _informDelegateAboutChildVisibility];
    
    return amountToMove;
}

- (CGFloat)contract
{
    CGFloat amountToMove = self.contractedCenterValue.y - self.view.center.y;

    [self _onAlphaUpdate:FLT_EPSILON];

    [self _updateCenter:self.contractedCenterValue];
    [self.subShyController contract];
    
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
