//
//  FlyingStytleView.m
//  FlyingEnglish
//
//  Created by BE_Air on 6/17/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//

#import "FlyingStytleView.h"
#import <QuartzCore/QuartzCore.h>


@implementation FlyingStytleView

- (id)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
    }
    return self;
}

-(void)awakeFromNib
{
    [self initData];
}

-(void) initData
{
    // Initialization code
    _subStyle=BEAINoAISubStyle;
}

-(void) changeStytle
{
    
    if (self.subStyle==BEAINoAISubStyle) {
        
        CAGradientLayer *l = [CAGradientLayer layer];
        self.alpha=0.9;
        l.frame = self.bounds;
        l.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor,
                    (id)[UIColor lightGrayColor].CGColor,
                    (id)[UIColor blackColor ].CGColor,
                    (id)[UIColor lightGrayColor].CGColor,
                    (id)[UIColor clearColor].CGColor, nil];
        l.startPoint = CGPointMake(0.0f, 0.5f);
        l.endPoint = CGPointMake(1.0f, 0.5f);
        
        self.layer.mask = l;
        self.subStyle=BEAISubHideBackgroundStyle;
    }
    else{    
        self.alpha=0;
        self.subStyle=BEAINoAISubStyle;
    }
}

-(void) reDrawStytle
{
    
    if (self.subStyle==BEAISubHideBackgroundStyle) {
        
        CAGradientLayer *l = [CAGradientLayer layer];
        self.alpha=0.9;
        l.frame = self.bounds;
        l.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor,
                    (id)[UIColor lightGrayColor].CGColor,
                    (id)[UIColor blackColor ].CGColor,
                    (id)[UIColor lightGrayColor].CGColor,
                    (id)[UIColor clearColor].CGColor, nil];
        l.startPoint = CGPointMake(0.0f, 0.5f);
        l.endPoint = CGPointMake(1.0f, 0.5f);
        
        self.layer.mask = l;
    }
    else{
        self.alpha=0;
    }
}

@end
