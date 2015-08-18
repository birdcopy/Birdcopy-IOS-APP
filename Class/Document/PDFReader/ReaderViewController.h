//
//  ReaderViewController.h
//  FlyingEnglish
//
//  Created by BE_Air on 11/16/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "ReaderDocument.h"
#import "ReaderMainToolbar.h"
#import "ReaderMainPagebar.h"
#import "ThumbsViewController.h"
#import <MessageUI/MessageUI.h>

#import "MuPageView.h"
#import "MuDialogCreator.h"
#import "MuUpdater.h"
#import "FlyingUIWebView.h"
#import <AVFoundation/AVFoundation.h>

@interface ReaderViewController : UIViewController<UIScrollViewDelegate,
                                                UIGestureRecognizerDelegate,
                                                MFMailComposeViewControllerDelegate,
                                                ReaderMainToolbarDelegate,
                                                ReaderMainPagebarDelegate,
                                                FlyingUIWebViewDelegate,
                                                ThumbsViewControllerDelegate,
                                                MuDialogCreator,
                                                MuUpdater,
                                                AVAudioPlayerDelegate>

@property (nonatomic, strong) NSString *lessonID;
@property (nonatomic, assign) BOOL playOnline;

-(ReaderDocument *) getDocument;

@end
