//
//  UIViewWithGradientBackground.m
//  RandomMusicPlayer
//
//  Created by Julio Andrés Carrettoni on 10/11/13.
//  Copyright (c) 2013 RoamTouch. All rights reserved.
//

#import "UIViewWithGradientBackground.h"

@interface UIViewWithGradientBackground()
@property (nonatomic, retain) CAGradientLayer* gradientLayer;
@end

@implementation UIViewWithGradientBackground

-(void) layoutSubviews {
    [super layoutSubviews];
    if (!self.gradientLayer) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0.15, 0);
        self.gradientLayer.endPoint = CGPointMake(0.85, 1.0);
        UIColor *color1 = [UIColor darkGrayColor];
        UIColor *color2 = [UIColor blackColor];
        self.gradientLayer.colors = @[(id)color1.CGColor, (id)color2.CGColor];
        
        [self.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    self.gradientLayer.frame = self.bounds;
}

@end

@interface UIWindowWithGradientBackground()
@property (nonatomic, retain) CAGradientLayer* gradientLayer;
@end

@implementation UIWindowWithGradientBackground

-(void) layoutSubviews {
    [super layoutSubviews];
    if (!self.gradientLayer) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0.15, 0);
        self.gradientLayer.endPoint = CGPointMake(0.85, 1.0);
        UIColor *color1 = [UIColor darkGrayColor];
        UIColor *color2 = [UIColor redColor];
        self.gradientLayer.colors = @[(id)color1.CGColor, (id)color2.CGColor];
        
        [self.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    self.gradientLayer.frame = self.bounds;
}


@end
