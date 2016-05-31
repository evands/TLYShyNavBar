//
//  TLYViewController.m
//  TLYShyNavBarDemo
//
//  Created by Mazyad Alabduljaleel on 6/12/14.
//  Copyright (c) 2014 Telly, Inc. All rights reserved.
//

#import "TLYViewController.h"
#import "TLYExtensionView.h"

@interface TLYViewController () <TLYShyNavBarManagerDelegate>

@property (nonatomic, assign) IBInspectable BOOL disableExtensionView;
@property (nonatomic, assign) IBInspectable BOOL stickyNavigationBar;
@property (nonatomic, assign) IBInspectable BOOL stickyExtensionView;
@property (nonatomic, assign) IBInspectable NSInteger fadeBehavior;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TLYViewController

#pragma mark - Init & Dealloc

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.disableExtensionView = NO;
        self.stickyNavigationBar = NO;
        self.stickyExtensionView = NO;
        self.fadeBehavior = TLYShyNavBarFadeSubviews;
        
        self.title = @"WTFox Say";
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    TLYExtensionView *view = nil;
    
    if (!self.disableExtensionView)
    {
        view = [[TLYExtensionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44.f)];
        view.backgroundColor = [UIColor redColor];
        view.needsUpdate = YES;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = view.bounds;
        [button addTarget:self action:@selector(extensionViewTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Click Me!" forState:UIControlStateNormal];
        
        [view addSubview:button];
    }
    
    /* Library code */
    self.shyNavBarManager.scrollView = self.scrollView;
    self.shyNavBarManager.delegate = self;
    /* Can then be remove by setting the ExtensionView to nil */
    [self.shyNavBarManager setExtensionView:view];
    /* Make navbar stick to the top */
    [self.shyNavBarManager setStickyNavigationBar:self.stickyNavigationBar];
    /* Make the extension view stick to the top */
    [self.shyNavBarManager setStickyExtensionView:self.stickyExtensionView];
    /* Navigation bar fade behavior */
    [self.shyNavBarManager setFadeBehavior:self.fadeBehavior];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = self.imageView.bounds.size;
}

#pragma mark - Action methods

- (void)extensionViewTapped:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"it works" message:nil delegate:nil cancelButtonTitle:@"OK!" otherButtonTitles:nil] show];
}

#pragma mark - TLYShyNavBarManagerDelegate

- (void)shyNavBarManager:(TLYShyNavBarManager *)manager didChangeExtensionViewHidden:(BOOL)hidden {
    NSLog(@"Hidden %i", hidden);
}

- (void)shyNavBarManager:(TLYShyNavBarManager *)manager childIsVisibleInPercent:(CGFloat)visiblePercent changeAnimated:(BOOL)animated withAnimationDuration:(NSTimeInterval)animationTime {
    NSLog(@"visiblePercent: %f \nchangeAnimated: %i \nanimationTime: %f", visiblePercent, animated, animationTime);
}

@end
