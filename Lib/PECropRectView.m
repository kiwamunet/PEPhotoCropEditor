//
//  PECropRectView.m
//  PhotoCropEditor
//
//  Created by kishikawa katsumi on 2013/05/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "PECropRectView.h"
#import "PEResizeControl.h"

@interface PECropRectView ()<PEResizeControlViewDelegate>

@property (nonatomic) PEResizeControl *topLeftCornerView;
@property (nonatomic) PEResizeControl *topRightCornerView;
@property (nonatomic) PEResizeControl *bottomLeftCornerView;
@property (nonatomic) PEResizeControl *bottomRightCornerView;
@property (nonatomic) PEResizeControl *topEdgeView;
@property (nonatomic) PEResizeControl *leftEdgeView;
@property (nonatomic) PEResizeControl *bottomEdgeView;
@property (nonatomic) PEResizeControl *rightEdgeView;

@property (nonatomic) CGRect initialRect;
@property (nonatomic) CGFloat fixedAspectRatio;
@property (nonatomic) CGPoint scrollOffset;


@end

@implementation PECropRectView

- (void)setScrollOffset:(CGPoint)point{
    _scrollOffset = point;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        
        self.showsGridMajor = NO;
        self.showsGridMinor = NO;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, 0, 0)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [[imageView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
        [[imageView layer] setBorderWidth:4.0];
        [self addSubview:imageView];
        
        self.topLeftCornerView = [[PEResizeControl alloc] init];
        self.topLeftCornerView.delegate = self;
        [self addSubview:self.topLeftCornerView];
        
        self.topRightCornerView = [[PEResizeControl alloc] init];
        self.topRightCornerView.delegate = self;
        [self addSubview:self.topRightCornerView];
        
        self.bottomLeftCornerView = [[PEResizeControl alloc] init];
        self.bottomLeftCornerView.delegate = self;
        [self addSubview:self.bottomLeftCornerView];
        
        self.bottomRightCornerView = [[PEResizeControl alloc] init];
        self.bottomRightCornerView.delegate = self;
        [self addSubview:self.bottomRightCornerView];
        
        self.topEdgeView = [[PEResizeControl alloc] init];
        self.topEdgeView.delegate = self;
        [self addSubview:self.topEdgeView];
        
        self.leftEdgeView = [[PEResizeControl alloc] init];
        self.leftEdgeView.delegate = self;
        [self addSubview:self.leftEdgeView];
        
        self.bottomEdgeView = [[PEResizeControl alloc] init];
        self.bottomEdgeView.delegate = self;
        [self addSubview:self.bottomEdgeView];
        
        self.rightEdgeView = [[PEResizeControl alloc] init];
        self.rightEdgeView.delegate = self;
        [self addSubview:self.rightEdgeView];
    }
    
    return self;
}

#pragma mark -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSArray *subviews = self.subviews;
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[PEResizeControl class]]) {
            if (CGRectContainsPoint(subview.frame, point)) {
                return subview;
            }
        }
    }
    
    return nil;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    
    for (NSInteger i = 0; i < 3; i++) {
        CGFloat borderPadding = 2.0f;
        
        if (self.showsGridMinor) {
            for (NSInteger j = 1; j < 3; j++) {
                [[UIColor colorWithRed:1.0f green:1.0f blue:0.0f alpha:0.3f] set];
                
                UIRectFill(CGRectMake(roundf(width / 3 / 3 * j + width / 3 * i), borderPadding, 1.0f, roundf(height) - borderPadding * 2));
                UIRectFill(CGRectMake(borderPadding, roundf(height / 3 / 3 * j + height / 3 * i), roundf(width) - borderPadding * 2, 1.0f));
            }
        }
        
        if (self.showsGridMajor) {
            if (i > 0) {
                [[UIColor whiteColor] set];
                
                UIRectFill(CGRectMake(roundf(width / 3 * i), borderPadding, 1.0f, roundf(height) - borderPadding * 2));
                UIRectFill(CGRectMake(borderPadding, roundf(height / 3 * i), roundf(width) - borderPadding * 2, 1.0f));
            }
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topLeftCornerView.frame = (CGRect){CGRectGetWidth(self.topLeftCornerView.bounds) / -2,
        CGRectGetHeight(self.topLeftCornerView.bounds) / -2,
        CGSizeZero};
    //self.topLeftCornerView.bounds.size};
    self.topLeftCornerView.backgroundColor = [UIColor yellowColor];
    
    self.topRightCornerView.frame = (CGRect){CGRectGetWidth(self.bounds) - CGRectGetWidth(self.topRightCornerView.bounds) / 2,
        CGRectGetHeight(self.topRightCornerView.bounds) / -2,
        CGSizeZero};
    //        self.topLeftCornerView.bounds.size};
    
    self.bottomLeftCornerView.frame = (CGRect){CGRectGetWidth(self.bottomLeftCornerView.bounds) / -2,
        CGRectGetHeight(self.bounds) - CGRectGetHeight(self.bottomLeftCornerView.bounds) / 2,
        CGSizeZero};
    //        self.bottomLeftCornerView.bounds.size};
    
    self.bottomRightCornerView.frame = (CGRect){CGRectGetWidth(self.bounds) - CGRectGetWidth(self.bottomRightCornerView.bounds) / 2,
        CGRectGetHeight(self.bounds) - CGRectGetHeight(self.bottomRightCornerView.bounds) / 2,
        CGSizeZero};
    //        self.bottomRightCornerView.bounds.size};
    
    self.topEdgeView.frame = (CGRect){CGRectGetMaxX(self.topLeftCornerView.frame),
        CGRectGetHeight(self.topEdgeView.frame) / -2, CGRectGetMinX(self.topRightCornerView.frame) - CGRectGetMaxX(self.topLeftCornerView.frame),
        CGRectGetHeight(self.topEdgeView.bounds)};
    
    self.leftEdgeView.frame = (CGRect){CGRectGetWidth(self.leftEdgeView.frame) / -2,
        CGRectGetMaxY(self.topLeftCornerView.frame),
        CGRectGetWidth(self.leftEdgeView.bounds),
        CGRectGetMinY(self.bottomLeftCornerView.frame) - CGRectGetMaxY(self.topLeftCornerView.frame)};
    
    self.bottomEdgeView.frame = (CGRect){CGRectGetMaxX(self.bottomLeftCornerView.frame),
        CGRectGetMinY(self.bottomLeftCornerView.frame) - self.bottomEdgeView.bounds.size.height / 2,
        CGRectGetMinX(self.bottomRightCornerView.frame) - CGRectGetMaxX(self.bottomLeftCornerView.frame),
        CGRectGetHeight(self.bottomEdgeView.bounds)};
    
    self.rightEdgeView.frame = (CGRect){CGRectGetWidth(self.bounds) - CGRectGetWidth(self.rightEdgeView.bounds) / 2,
        CGRectGetMaxY(self.topRightCornerView.frame),
        CGRectGetWidth(self.rightEdgeView.bounds),
        CGRectGetMinY(self.bottomRightCornerView.frame) - CGRectGetMaxY(self.topRightCornerView.frame)};
}

#pragma mark -

- (void)setShowsGridMajor:(BOOL)showsGridMajor
{
    _showsGridMajor = showsGridMajor;
    [self setNeedsDisplay];
}

- (void)setShowsGridMinor:(BOOL)showsGridMinor
{
    _showsGridMinor = showsGridMinor;
    [self setNeedsDisplay];
}

- (void)setKeepingAspectRatio:(BOOL)keepingAspectRatio
{
    _keepingAspectRatio = keepingAspectRatio;
    
    if (self.keepingAspectRatio) {
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds);
        self.fixedAspectRatio = fminf(width / height, height / width);
    }
}

#pragma mark -

- (void)resizeControlViewDidBeginResizing:(PEResizeControl *)resizeControlView
{
    self.initialRect = self.frame;
    
    if ([self.delegate respondsToSelector:@selector(cropRectViewDidBeginEditing:)]) {
        [self.delegate cropRectViewDidBeginEditing:self];
    }
}

- (void)resizeControlViewDidResize:(PEResizeControl *)resizeControlView
{
    self.frame = [self cropRectMakeWithResizeControlView:resizeControlView];
    
    if ([self.delegate respondsToSelector:@selector(cropRectViewEditingChanged:)]) {
        [self.delegate cropRectViewEditingChanged:self];
    }
}

- (void)resizeControlViewDidEndResizing:(PEResizeControl *)resizeControlView
{
}

- (CGRect)cropRectMakeWithResizeControlView:(PEResizeControl *)resizeControlView
{
    CGRect rect = self.frame;
    
    CGFloat limitY = self.initialRect.origin.y + resizeControlView.translation.y;
    if (limitY <= 1.0f) {
        limitY = 1.0f;
    }
    
    if (limitY >= self.superview.frame.size.height - self.frame.size.height) {
        limitY = self.superview.frame.size.height - self.frame.size.height;
    }
    
    rect = CGRectMake(CGRectGetMinX(self.initialRect),
                      limitY,
                      self.frame.size.width,
                      self.frame.size.height);
    return rect;
}

- (CGRect)constrainedRectWithRectBasisOfWidth:(CGRect)rect aspectRatio:(CGFloat)aspectRatio
{
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    if (width < height) {
        height = width / self.fixedAspectRatio;
    } else {
        height = width * self.fixedAspectRatio;
    }
    rect.size = CGSizeMake(width, height);
    
    return rect;
}

- (CGRect)constrainedRectWithRectBasisOfHeight:(CGRect)rect aspectRatio:(CGFloat)aspectRatio
{
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    if (width < height) {
        width = height * self.fixedAspectRatio;
    } else {
        width = height / self.fixedAspectRatio;
    }
    rect.size = CGSizeMake(width, height);
    
    return rect;
}

@end
