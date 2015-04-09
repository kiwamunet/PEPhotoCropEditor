//
//  PECropView.m
//  PhotoCropEditor
//
//  Created by kishikawa katsumi on 2013/05/19.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "PECropView.h"
#import "PECropRectView.h"
#import "UIImage+PECrop.h"

static const CGFloat MarginTop = 0;
static const CGFloat MarginBottom = MarginTop;
static const CGFloat MarginLeft = 0;
static const CGFloat MarginRight = MarginLeft;
static const CGFloat aspectRatio = 9.0 / 16.0;

@interface PECropView () <UIScrollViewDelegate, UIGestureRecognizerDelegate, PECropRectViewDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *zoomingView;
//@property (nonatomic) UIImageView *imageView;

@property (nonatomic) PECropRectView *cropRectView;
@property (nonatomic) UIView *topOverlayView;
@property (nonatomic) UIView *leftOverlayView;
@property (nonatomic) UIView *rightOverlayView;
@property (nonatomic) UIView *bottomOverlayView;

@property (nonatomic) CGRect insetRect;
@property (nonatomic) CGRect editingRect;

@property (nonatomic, getter = isResizing) BOOL resizing;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

@end

@implementation PECropView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor clearColor];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.maximumZoomScale = 20.0f;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    self.scrollView.bouncesZoom = NO;
    self.scrollView.clipsToBounds = NO;
    [self addSubview:self.scrollView];
    
    self.cropRectView = [[PECropRectView alloc] init];
    self.cropRectView.delegate = self;
    [self addSubview:self.cropRectView];
    
    self.topOverlayView = [[UIView alloc] init];
    self.topOverlayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    [self addSubview:self.topOverlayView];
    
    self.leftOverlayView = [[UIView alloc] init];
    self.leftOverlayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    [self addSubview:self.leftOverlayView];
    
    self.rightOverlayView = [[UIView alloc] init];
    self.rightOverlayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    [self addSubview:self.rightOverlayView];
    
    self.bottomOverlayView = [[UIView alloc] init];
    self.bottomOverlayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    [self addSubview:self.bottomOverlayView];
}

#pragma mark -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.userInteractionEnabled) {
        return nil;
    }
    
    UIView *hitView = [self.cropRectView hitTest:[self convertPoint:point toView:self.cropRectView] withEvent:event];
    if (hitView) {
        return hitView;
    }
    CGPoint locationInImageView = [self convertPoint:point toView:self.zoomingView];
    CGPoint zoomedPoint = CGPointMake(locationInImageView.x * self.scrollView.zoomScale, locationInImageView.y * self.scrollView.zoomScale);
    if (CGRectContainsPoint(self.zoomingView.frame, zoomedPoint)) {
        return self.scrollView;
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.image) {
        return;
    }
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        self.editingRect = CGRectInset(self.bounds, MarginLeft, MarginTop);
    } else {
        self.editingRect = CGRectInset(self.bounds, MarginLeft, MarginLeft);
    }
    
    if (!self.imageView) {
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
            self.insetRect = CGRectInset(self.bounds, MarginLeft, MarginTop);
        } else {
            self.insetRect = CGRectInset(self.bounds, MarginLeft, MarginLeft);
        }
        
        [self setupImageView];
    }
    
    if (!self.isResizing) {
        [self layoutCropRectViewWithCropRect:CGRectMake(0,
                                                        (self.scrollView.center.y - (self.scrollView.frame.size.width * aspectRatio) / 2),
                                                        self.scrollView.frame.size.width,
                                                        (self.scrollView.frame.size.width * aspectRatio))];
        
    }
    
    self.interfaceOrientation = interfaceOrientation;
}

- (void)layoutCropRectViewWithCropRect:(CGRect)cropRect
{
    self.cropRectView.frame = cropRect;
    [self layoutOverlayViewsWithCropRect:cropRect];
}

- (void)layoutOverlayViewsWithCropRect:(CGRect)cropRect
{
    self.topOverlayView.frame = CGRectMake(0.0f,
                                           0.0f,
                                           CGRectGetWidth(self.bounds),
                                           CGRectGetMinY(cropRect));
    self.leftOverlayView.frame = CGRectMake(0.0f,
                                            CGRectGetMinY(cropRect),
                                            CGRectGetMinX(cropRect),
                                            CGRectGetHeight(cropRect));
    self.rightOverlayView.frame = CGRectMake(CGRectGetMaxX(cropRect),
                                             CGRectGetMinY(cropRect),
                                             CGRectGetWidth(self.bounds) - CGRectGetMaxX(cropRect),
                                             CGRectGetHeight(cropRect));
    self.bottomOverlayView.frame = CGRectMake(0.0f,
                                              CGRectGetMaxY(cropRect),
                                              CGRectGetWidth(self.bounds),
                                              CGRectGetHeight(self.bounds) - CGRectGetMaxY(cropRect));
    
}

- (void)setupImageView
{
    CGRect cropRect = self.bounds;
    self.scrollView.frame = cropRect;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.width * (self.image.size.height / self.image.size.width));
    self.zoomingView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                self.scrollView.bounds.size.width,
                                                                self.scrollView.bounds.size.height)];
    self.zoomingView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.zoomingView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.zoomingView.bounds.origin.x,
                                                                   self.zoomingView.bounds.origin.y,
                                                                   self.scrollView.frame.size.width,
                                                                   (self.scrollView.frame.size.width * (self.image.size.height / self.image.size.width)))];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = [UIImage imageWithCGImage:self.image.CGImage scale:self.image.scale orientation:self.image.imageOrientation];
    [self.zoomingView addSubview:self.imageView];
}

#pragma mark -

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    [self.zoomingView removeFromSuperview];
    self.zoomingView = nil;
    
    [self setNeedsLayout];
}

- (void)setKeepingCropAspectRatio:(BOOL)keepingCropAspectRatio
{
    _keepingCropAspectRatio = keepingCropAspectRatio;
    self.cropRectView.keepingAspectRatio = self.keepingCropAspectRatio;
}

- (void)setCropAspectRatio:(CGFloat)aspectRatio andCenter:(BOOL)center
{
    CGRect cropRect = self.scrollView.frame;
    CGFloat width = CGRectGetWidth(cropRect);
    CGFloat height = CGRectGetHeight(cropRect);
    if (aspectRatio <= 1.0f) {
        width = height * aspectRatio;
        if (width > CGRectGetWidth(self.imageView.bounds)) {
            width = CGRectGetWidth(cropRect);
            height = width / aspectRatio;
        }
    } else {
        height = width / aspectRatio;
        if (height > CGRectGetHeight(self.imageView.bounds)) {
            height = CGRectGetHeight(cropRect);
            width = height * aspectRatio;
        }
    }
    cropRect.size = CGSizeMake(width, height);
    [self zoomToCropRect:cropRect andCenter:center];
}

- (void)setCropAspectRatio:(CGFloat)aspectRatio
{
    [self setCropAspectRatio:aspectRatio andCenter:YES];
}

- (CGFloat)cropAspectRatio
{
    CGRect cropRect = self.scrollView.frame;
    CGFloat width = CGRectGetWidth(cropRect);
    CGFloat height = CGRectGetHeight(cropRect);
    return width / height;
}

- (void)setCropRect:(CGRect)cropRect
{
    [self zoomToCropRect:cropRect];
}

- (CGRect)cropRect
{
    return self.scrollView.frame;
}

- (void)setImageCropRect:(CGRect)imageCropRect
{
    [self resetCropRect];
    
    CGRect scrollViewFrame = self.scrollView.frame;
    CGSize imageSize = self.image.size;
    
    CGFloat scale = MIN(CGRectGetWidth(scrollViewFrame) / imageSize.width,
                        CGRectGetHeight(scrollViewFrame) / imageSize.height);
    
    CGFloat x = CGRectGetMinX(imageCropRect) * scale + CGRectGetMinX(scrollViewFrame);
    CGFloat y = CGRectGetMinY(imageCropRect) * scale + CGRectGetMinY(scrollViewFrame);
    CGFloat width = CGRectGetWidth(imageCropRect) * scale;
    CGFloat height = CGRectGetHeight(imageCropRect) * scale;
    
    CGRect rect = CGRectMake(x, y, width, height);
    CGRect intersection = CGRectIntersection(rect, scrollViewFrame);
    
    if (!CGRectIsNull(intersection)) {
        self.cropRect = intersection;
    }
}

- (void)resetCropRect
{
    [self resetCropRectAnimated:NO];
}

- (void)resetCropRectAnimated:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    
    self.imageView.transform = CGAffineTransformIdentity;
    
    CGSize contentSize = self.scrollView.contentSize;
    CGRect initialRect = CGRectMake(0.0f, 0.0f, contentSize.width, contentSize.height);
    [self.scrollView zoomToRect:initialRect animated:NO];
    
    self.scrollView.bounds = self.imageView.bounds;
    
    [self layoutCropRectViewWithCropRect:self.scrollView.bounds];
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (UIImage *)croppedImage
{
    return [self.imageView.image rotatedImageWithtransform:self.rotation croppedToRect:self.zoomedCropRect];
}

- (CGRect)zoomedCropRect
{
    CGSize size = self.image.size;
    CGFloat ratio = 1.0f;
    ratio = self.imageView.frame.size.width / size.width;
    
    CGRect cropRect = [self.cropRectView convertRect:self.cropRectView.bounds toView:self.imageView];
    CGRect zoomedCropRect = CGRectMake(cropRect.origin.x / ratio,
                                       cropRect.origin.y / ratio,
                                       cropRect.size.width / ratio,
                                       cropRect.size.height / ratio);
    
    return zoomedCropRect;
}

- (BOOL)userHasModifiedCropArea
{
    CGRect zoomedCropRect = CGRectIntegral(self.zoomedCropRect);
    return (!CGPointEqualToPoint(zoomedCropRect.origin, CGPointZero) ||
            !CGSizeEqualToSize(zoomedCropRect.size, self.image.size) ||
            !CGAffineTransformEqualToTransform(self.rotation, CGAffineTransformIdentity));
}

- (CGAffineTransform)rotation
{
    return self.imageView.transform;
}

- (CGFloat)rotationAngle
{
    CGAffineTransform rotation = self.imageView.transform;
    return atan2f(rotation.b, rotation.a);
}

- (void)setRotationAngle:(CGFloat)rotationAngle
{
    self.imageView.transform = CGAffineTransformMakeRotation(rotationAngle);
}

- (void)setRotationAngle:(CGFloat)rotationAngle snap:(BOOL)snap
{
    if (snap)
    {
        rotationAngle = nearbyintf(rotationAngle / M_PI_2) * M_PI_2;
    }
    self.rotationAngle = rotationAngle;
}

- (CGRect)cappedCropRectInImageRectWithCropRectView:(PECropRectView *)cropRectView
{
    CGRect cropRect = cropRectView.frame;
    return cropRect;
}

- (void)automaticZoomIfEdgeTouched:(CGRect)cropRect
{
    if (CGRectGetMinX(cropRect) < CGRectGetMinX(self.editingRect) - 5.0f ||
        CGRectGetMaxX(cropRect) > CGRectGetMaxX(self.editingRect) + 5.0f ||
        CGRectGetMinY(cropRect) < CGRectGetMinY(self.editingRect) - 5.0f ||
        CGRectGetMaxY(cropRect) > CGRectGetMaxY(self.editingRect) + 5.0f) {
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self zoomToCropRect:self.cropRectView.frame];
        } completion:NULL];
    }
}

#pragma mark -

- (void)cropRectViewDidBeginEditing:(PECropRectView *)cropRectView
{
    self.resizing = YES;
}

- (void)cropRectViewEditingChanged:(PECropRectView *)cropRectView
{
    CGRect cropRect = [self cappedCropRectInImageRectWithCropRectView:cropRectView];
    [self layoutCropRectViewWithCropRect:cropRect];
}

- (void)cropRectViewDidEndEditing:(PECropRectView *)cropRectView
{
    self.resizing = NO;
    [self zoomToCropRect:self.cropRectView.frame];
}

- (void)zoomToCropRect:(CGRect)toRect andCenter:(BOOL)center
{
    if (CGRectEqualToRect(self.scrollView.frame, toRect)) {
        return;
    }
    
    CGFloat width = CGRectGetWidth(toRect);
    CGFloat height = CGRectGetHeight(toRect);
    
    CGFloat scale = MIN(CGRectGetWidth(self.editingRect) / width, CGRectGetHeight(self.editingRect) / height);
    
    CGFloat scaledWidth = width * scale;
    CGFloat scaledHeight = height * scale;
    CGRect cropRect = CGRectMake((CGRectGetWidth(self.bounds) - scaledWidth) / 2,
                                 (CGRectGetHeight(self.bounds) - scaledHeight) / 2,
                                 scaledWidth,
                                 scaledHeight);
    
    CGRect zoomRect = [self convertRect:toRect toView:self.zoomingView];
    zoomRect.size.width = CGRectGetWidth(cropRect) / (self.scrollView.zoomScale * scale);
    zoomRect.size.height = CGRectGetHeight(cropRect) / (self.scrollView.zoomScale * scale);
    
    if(center) {
        CGRect imageViewBounds = self.imageView.bounds;
        zoomRect.origin.y = (CGRectGetHeight(imageViewBounds) / 2) - (CGRectGetHeight(zoomRect) / 2);
        zoomRect.origin.x = (CGRectGetWidth(imageViewBounds) / 2) - (CGRectGetWidth(zoomRect) / 2);
    }
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollView.bounds = cropRect;
        [self.scrollView zoomToRect:zoomRect animated:NO];
    } completion:NULL];
}

- (void)zoomToCropRect:(CGRect)toRect
{
    [self zoomToCropRect:toRect andCenter:NO];
}

#pragma mark -

- (void)handleRotation:(UIRotationGestureRecognizer *)gestureRecognizer
{
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.zoomingView;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGPoint contentOffset = scrollView.contentOffset;
    *targetContentOffset = contentOffset;
    [self.cropRectView setScrollOffset:contentOffset];
}

@end
