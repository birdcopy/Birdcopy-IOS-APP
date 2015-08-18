//  FlyingLessonListViewController.m
//  FlyingEnglish
//
//  Created by BE_Air on 6/5/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//

#import "FlyingLessonListViewController.h"
#import "FlyingLessonViewCell.h"
#import "FlyingLessonVC.h"
#import "NSString+FlyingExtention.h"
#import "SoundPlayer.h"
#import "shareDefine.h"
#import "FlyingLoadingView.h"
#import "UIView+Autosizing.h"
#import "iFlyingAppDelegate.h"
#import "FlyingPubLessonData.h"
#import "SIAlertView.h"
#import <AFNetworking.h>
#import "FlyingSearchViewController.h"
#import "RESideMenu.h"
#import "SDImageCache.h"
#import "UIImage+localFile.h"
#import "FlyingWebViewController.h"
#import "RCDChatListViewController.h"
#import "UIView+Toast.h"
#import "RCDChatViewController.h"
#import "FlyingHttpTool.h"
#import "UIView+Toast.h"

@interface FlyingLessonListViewController ()<UIViewControllerRestoration>
{
    NSInteger            _maxNumOfLessons;
    NSInteger            _currentLodingIndex;
    
    BOOL                 _refresh;
    UIRefreshControl    *_refreshControl;
}

@end

@implementation FlyingLessonListViewController

+ (UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    UIViewController *retViewController = [[FlyingLessonListViewController alloc] init];
    return retViewController;
}

-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.tagString forKey:@"tagString"];
}

-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.tagString = [coder decodeObjectForKey:@"tagString"];
    
    self.title=self.tagString;
    [self reloadAll];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.restorationIdentifier = @"FlyingLessonListViewController";
    self.restorationClass      = [self class];
    
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.000];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.sortByTime=YES;
    self.recommoned=NO;

    [self addBackFunction];
    
    //更新欢迎语言
    self.title =@"内容列表";
    if (self.tagString) {
        
        self.title=self.tagString;
    }
    
    //顶部导航
    UIImage* image= [UIImage imageNamed:@"menu"];
    CGRect frame= CGRectMake(0, 0, 28, 28);
    UIButton* menuButton= [[UIButton alloc] initWithFrame:frame];
    [menuButton setBackgroundImage:image forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* menuBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    
    image= [UIImage imageNamed:@"back"];
    frame= CGRectMake(0, 0, 28, 28);
    UIButton* backButton= [[UIButton alloc] initWithFrame:frame];
    [backButton setBackgroundImage:image forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* backBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:backBarButtonItem,menuBarButtonItem,nil];
    
    [self reloadAll];

    dispatch_async(dispatch_get_main_queue() , ^{
        [self updateChatIcon];
    });
}

-(void) updateChatIcon
{
    int unreadMsgCount = [[RCIMClient sharedRCIMClient]getUnreadCount: @[@(ConversationType_PRIVATE),@(ConversationType_DISCUSSION), @(ConversationType_PUBLICSERVICE), @(ConversationType_PUBLICSERVICE),@(ConversationType_GROUP)]];
    
    UIImage *image;
    if(unreadMsgCount>0)
    {
        image = [UIImage imageNamed:@"chat"];
    }
    else
    {
        image= [UIImage imageNamed:@"chat_b"];
    }
    
    CGRect frame= CGRectMake(0, 0, 24, 24);
    UIButton* chatButton= [[UIButton alloc] initWithFrame:frame];
    [chatButton setBackgroundImage:image forState:UIControlStateNormal];
    [chatButton addTarget:self action:@selector(doChat) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* chatBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:chatButton];
    
    image= [UIImage imageNamed:@"search"];
    frame= CGRectMake(0, 0, 24, 24);
    UIButton* searchButton= [[UIButton alloc] initWithFrame:frame];
    [searchButton setBackgroundImage:image forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* searchBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:searchButton];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:chatBarButtonItem, searchBarButtonItem, nil];
}

- (void)refreshNow:(UIRefreshControl *)refreshControl
{
    
    if ([AFNetworkReachabilityManager sharedManager].reachable)
    {
        _refresh=YES;
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新中..."];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self reloadAll];
        });
    }
    else
    {
        [_refreshControl endRefreshing];
        [self.view makeToast:@"请联网后再试一下!" duration:3 position:CSToastPositionCenter];
    }
}
//////////////////////////////////////////////////////////////
#pragma  Data related
//////////////////////////////////////////////////////////////
-(void) reloadAll
{
    if (!self.lessonCollectView)
    {
        self.lessonCollectView = [[PSCollectionView alloc] initWithFrame:CGRectMake(0.0f, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        
        if (INTERFACE_IS_PAD )
        {
            self.lessonCollectView.numColsPortrait  = 4;
            self.lessonCollectView.numColsLandscape = 6;
            
        } else
        {
            self.lessonCollectView.numColsPortrait  = 2;
            self.lessonCollectView.numColsLandscape = 3;
        }
        
        //self.lessonCollectView.delegate = self; // This is for UIScrollViewDelegate
        self.lessonCollectView.collectionViewDelegate = self;
        self.lessonCollectView.collectionViewDataSource = self;
        self.lessonCollectView.backgroundColor = [UIColor clearColor];
        self.lessonCollectView.autoresizingMask = ~UIViewAutoresizingNone;
        
        //Add a footer view
        CGRect loadingRect  = CGRectMake(0, 0, self.view.frame.size.width, 44);
        FlyingLoadingView* loadingView = [[FlyingLoadingView alloc] initWithFrame:loadingRect];
        loadingView.loadingViewDelegate=self;
        self.lessonCollectView.footerView = loadingView;
        
        [self.view addSubview:self.lessonCollectView];
        
        self.currentData = [NSMutableArray new];
        _currentLodingIndex=0;
        _maxNumOfLessons=NSIntegerMax;
        
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refreshNow:) forControlEvents:UIControlEventValueChanged];
        [self.lessonCollectView addSubview:_refreshControl];
    }
    else
    {
        [(FlyingLoadingView*)self.lessonCollectView.footerView showTitle:nil];
        
        [self.currentData removeAllObjects];
        _currentLodingIndex=0;
        _maxNumOfLessons=NSIntegerMax;
    }
    
    [self downloadMore];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && ([self.view window] == nil) ) {
        self.view = nil;
        [self my_viewDidUnload];
    }
}

- (void)viewDidUnload
{
    
    [super viewDidUnload];
    [self my_viewDidUnload];
}

- (void)my_viewDidUnload
{
    
    [self setLessonCollectView:nil];
    [self.currentData removeAllObjects];
    self.currentData=nil;
}

//////////////////////////////////////////////////////////////
#pragma mark PSCollection
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfRowsInCollectionView:(PSCollectionView *)collectionView
{
    return [_currentData count];
}

- (PSCollectionViewCell *)collectionView:(PSCollectionView *)collectionView cellForRowAtIndex:(NSInteger)index
{
    
    if (_currentData.count==0) {
        
        //[self.helpLabel  showTip:@"没有内容" dismissAfterDelay:3];
        return nil;
    }
    
    FlyingLessonViewCell *v = (FlyingLessonViewCell *)[self.lessonCollectView dequeueReusableViewForClass:[FlyingLessonViewCell class]];
    if (!v) {
        v = [[FlyingLessonViewCell alloc] initWithFrame:CGRectZero];
    }
    
    [v collectionView:self.lessonCollectView fillCellWithObject:[_currentData objectAtIndex:index] atIndex:index];
    
    [v setLittleShadow];
    
    return v;
}

- (CGFloat)collectionView:(PSCollectionView *)collectionView heightForRowAtIndex:(NSInteger)index
{
    FlyingPubLessonData* lesson = [_currentData objectAtIndex:index];
    return  [FlyingLessonViewCell  rowHeightForObject:lesson inColumnWidth:self.lessonCollectView.colWidth];
}

- (void)collectionView:(PSCollectionView *)collectionView didSelectCell:(PSCollectionViewCell *)cell atIndex:(NSInteger)index
{
    if (_currentData.count!=0) {
        
        FlyingPubLessonData* lessonData = [_currentData objectAtIndex:index];
        
        FlyingLessonVC *lessonPage = [[FlyingLessonVC alloc] init];
        [lessonPage setTheLesson:lessonData];
        
        [self.navigationController pushViewController:lessonPage animated:YES];
        
        /*
        if ([lessonData.contentType isEqualToString:KContentTypePageWeb] ) {
            
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            FlyingWebViewController * webpage=[storyboard instantiateViewControllerWithIdentifier:@"webpage"];
            [webpage setWebURL:lessonData.contentURL];
            [webpage setLessonID:lessonData.lessonID];
            
            [self.navigationController pushViewController:webpage animated:YES];
        }
        else
        {
            FlyingLessonVC *lessonPage = [[FlyingLessonVC alloc] init];
            [lessonPage setTheLesson:lessonData];
            
            [self.navigationController pushViewController:lessonPage animated:YES];
        }
         */
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Download data from Learning center
//////////////////////////////////////////////////////////////

- (void)downloadMore
{
    if (_currentData.count<_maxNumOfLessons)
    {
        _currentLodingIndex++;
        
        if (self.recommoned)
        {
            
            [FlyingHttpTool getCoverListByTagURLForPageNumber:_currentLodingIndex
                                                   SortbyTime:self.sortByTime
                                                   Completion:^(NSArray *lessonList,NSInteger allRecordCount) {
                                                       //
                                                       if (lessonList) {
                                                           [self.currentData addObjectsFromArray:lessonList];
                                                       }
                                                       
                                                       _maxNumOfLessons=allRecordCount;
                                                       
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self finishLoadingData];
                                                       });
                                                   }];
        }
        else
        {
            
            [FlyingHttpTool getLessonListByTagForPageNumber:_currentLodingIndex
                                          lessonConcentType:self.contentType
                                               DownloadType:self.downloadType
                                                        Tag:self.tagString
                                                 SortbyTime:self.sortByTime
                                                  Recommend:self.recommoned
                                                 Completion:^(NSArray *lessonList, NSInteger allRecordCount) {
                                                     //
                                                     if (lessonList) {
                                                         [self.currentData addObjectsFromArray:lessonList];
                                                     }
                                                     
                                                     _maxNumOfLessons=allRecordCount;
                                                     
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [self finishLoadingData];
                                                     });
                                                 }];
        }
    }
}
-(void) finishLoadingData
{
    //更新下拉刷新
    if(_refresh)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *lastUpdate = [NSString stringWithFormat:@"刷新时间：%@", [formatter stringFromDate:[NSDate date]]];
        
        _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdate];
        
        [_refreshControl endRefreshing];
        _refresh=NO;
    }

    //更新界面
    if (_currentData.count!=0)
    {
        [self.lessonCollectView reloadData];
    }
    else
    {
        [self.view makeToast:@"请联网后再试一下!" duration:3 position:CSToastPositionCenter];
    }
    
    //处理footview
    if (_currentData.count>=_maxNumOfLessons) {
        
        FlyingLoadingView * loadingView= (FlyingLoadingView*)self.lessonCollectView.footerView;
        if (loadingView)
        {
            [loadingView showTitle:@"点击右上角搜索更多内容!"];
        }
    }
    else
    {
        FlyingLoadingView * loadingView= (FlyingLoadingView*)self.lessonCollectView.footerView;
        if (loadingView)
        {
            [loadingView showTitle:@"加载更多内容"];
        }
    }
}

- (void)handleError:(NSError *)error
{
    
    //[self.helpLabel  showTip:@"不能显示课程目录" dismissAfterDelay:3];
}

//////////////////////////////////////////////////////////////
#pragma only portart events
//////////////////////////////////////////////////////////////
-(void) dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(BOOL) isRSSLesson:(NSString*) url
{
    NSRange textRange;
    NSString * substring= @"rss";
    textRange =[url rangeOfString:substring];
    
    if(textRange.location == NSNotFound)
    {
        return NO;
    }
    else{
    
        return YES;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark socail Related
//////////////////////////////////////////////////////////////

- (void) showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void) doSomething
{
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    FlyingSearchViewController * search=[storyboard instantiateViewControllerWithIdentifier:@"search"];
    [self.navigationController pushViewController:search animated:YES];
}

- (void) doChat
{
    if (INTERFACE_IS_PAD) {
        
        [self.view makeToast:@"PAD版本暂时不支持聊天功能!！"];
        
        return;
    }
    
    RCDChatListViewController  * chatList=[[RCDChatListViewController alloc] init];
    [self.navigationController pushViewController:chatList animated:YES];
}

- (void) doSearch
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    FlyingSearchViewController * search=[storyboard instantiateViewControllerWithIdentifier:@"search"];
    [self.navigationController pushViewController:search animated:YES];
}

//////////////////////////////////////////////////////////////
#pragma mark controller events
//////////////////////////////////////////////////////////////

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate shakeNow];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self resignFirstResponder];
    [super viewDidDisappear:animated];
}

- (void) addBackFunction
{
    
    //在一个函数里面（初始化等）里面添加要识别触摸事件的范围
    UISwipeGestureRecognizer *recognizer= [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizer];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePinch:)];
    
    [self.view addGestureRecognizer:pinchGestureRecognizer];
}

-(void) handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer
{
    if(recognizer.direction==UISwipeGestureRecognizerDirectionRight) {
        
        [self dismiss];
    }
}

-(void) handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    if ((recognizer.state ==UIGestureRecognizerStateEnded) || (recognizer.state ==UIGestureRecognizerStateCancelled)) {
        
        [self dismiss];
    }
}

@end
