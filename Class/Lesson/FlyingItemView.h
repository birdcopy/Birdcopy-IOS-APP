//
//  FlyingItemView.h
//  FlyingEnglish
//
//  Created by BE_Air on 10/1/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UITouch (TouchSorting)

- (NSComparisonResult)compareAddress:(id)obj;

@end

@interface FlyingItemView : UIView
{
    CGAffineTransform         originalTransform;
    CFMutableDictionaryRef    touchBeginPoints;
}

@property (strong, nonatomic)  NSString        *word;
@property (strong, nonatomic)  NSString        *lemma;
@property (strong, nonatomic)  NSString        *appTag;
@property (strong, nonatomic)  NSMutableString *desc;

@property (strong, nonatomic)  NSString *lessonID;  //为了方便发音保存的冗余信息

@property (assign, nonatomic)  BOOL  fullScreenModle;

- (void)  drawWithLemma:(NSString *) lemma      AppTag: (NSString*) appTag;
- (void)  dismissViewAnimated:(BOOL) animated;

@end
