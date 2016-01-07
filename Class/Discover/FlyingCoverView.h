//
//  FlyingCoverView.h
//  FlyingEnglish
//
//  Created by vincent on 15/9/14.
//  Copyright (c) 2014 vincent sung. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlyingCoverViewDelegate;

@interface FlyingCoverView : UIView<UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView   *coverScrollView;

@property (strong, nonatomic) UILabel        *coverTitle;
@property (strong, nonatomic) UIPageControl  *coverControl;

@property (strong, nonatomic) NSMutableArray          *coverData;
@property (strong, nonatomic) NSMutableDictionary     *coverImageViewDic;

@property (weak,   nonatomic) id <FlyingCoverViewDelegate> coverViewDelegate;

-(void) loadData;

@end

#pragma mark - Delegate

@protocol FlyingCoverViewDelegate <NSObject>

@optional
- (void) showFeatureContent;
- (void) touchCover:(id)lessonPubData;

- (NSString*) getAuthor;

@end
