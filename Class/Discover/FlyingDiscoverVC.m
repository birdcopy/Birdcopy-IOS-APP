//
//  FlyingDiscoverContent.m
//  FlyingEnglish
//
//  Created by vincent on 9/5/15.
//  Copyright (c) 2015 BirdEngish. All rights reserved.
//
#import "FlyingDiscoverVC.h"
#import "shareDefine.h"
#import "NSString+FlyingExtention.h"
#import "FlyingLessonParser.h"
#import "FlyingContentListVC.h"
#import "FlyingPubLessonData.h"
#import <UIImageView+AFNetworking.h>
#import "FlyingLoadingView.h"
#import "FlyingConversationListVC.h"
#import "FlyingSearchViewController.h"
#import "FlyingContentVC.h"
#import "iFlyingAppDelegate.h"
#import "UIView+Autosizing.h"
#import "FlyingCoverView.h"
#import "FlyingCoverData.h"
#import "FlyingCoverViewCell.h"
#import "UICKeyChainStore.h"
#import <AFNetworking/AFNetworking.h>
#import "UIView+Toast.h"
#import "AFHttpTool.h"
#import "FlyingHttpTool.h"

#import "FlyingNavigationController.h"
#import "FlyingDataManager.h"
#import "FlyingConversationVC.h"


@interface FlyingDiscoverVC ()<UIViewControllerRestoration>

{
    NSInteger            _maxNumOfTags;
    NSInteger            _currentLodingIndex;
    
    BOOL                 _refresh;
    UIRefreshControl    *_refreshControl;
}

@property (nonatomic,strong) UIButton* menuButton;


@end

@implementation FlyingDiscoverVC

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                                                            coder:(NSCoder *)coder
{
    UIViewController *vc = [self new];
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
}

- (id)init
{
    if ((self = [super init]))
    {
        // Custom initialization
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _refresh=NO;
        
    self.title=@"推荐";
    
    //顶部导航
    UIButton* searchButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [searchButton setBackgroundImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* searchBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:searchButton];
    
    self.navigationItem.rightBarButtonItem = searchBarButtonItem;
    
    if (!self.domainID) {
        
        self.domainID = [FlyingDataManager getBusinessID];
    }
        
    [self reloadAll];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void) willDismiss
{
}

- (void) doSearch
{
    FlyingSearchViewController * search=[[FlyingSearchViewController alloc] init];
    
    search.domainID = self.domainID;
    search.domainType = self.domainType;
    
    [search setSearchType:BEFindLesson];
    [self.navigationController pushViewController:search animated:YES];
}

//////////////////////////////////////////////////////////////
#pragma  Data related
//////////////////////////////////////////////////////////////
-(void) reloadAll
{
    if (!self.homeFeatureTagPSColeectionView)
    {
        self.homeFeatureTagPSColeectionView = [[PSCollectionView alloc] initWithFrame:CGRectMake(0.0f, 0, self.view.frame.size.width, self.view.frame.size.height)];
        self.homeFeatureTagPSColeectionView.isHomeView=YES;
        
        if (INTERFACE_IS_PAD )
        {
            self.homeFeatureTagPSColeectionView.numColsPortrait  = 4;
            self.homeFeatureTagPSColeectionView.numColsLandscape = 6;
            
        } else
        {
            self.homeFeatureTagPSColeectionView.numColsPortrait  = 2;
            self.homeFeatureTagPSColeectionView.numColsLandscape = 4;
        }
        
        //self.homeFeatureTagPSColeectionView.delegate = self; // This is for UIScrollViewDelegate
        self.homeFeatureTagPSColeectionView.collectionViewDelegate = self;
        self.homeFeatureTagPSColeectionView.collectionViewDataSource = self;
        self.homeFeatureTagPSColeectionView.backgroundColor = [UIColor clearColor];
        self.homeFeatureTagPSColeectionView.autoresizingMask = ~UIViewAutoresizingNone;
        
        //Add cover view
        if(self.shoudLoaingFeature)
        {
            CGRect  featureRect  = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*210/320);
            FlyingCoverView* coverFlow = [[FlyingCoverView alloc] initWithFrame:featureRect];
            [coverFlow setDomainID:self.domainID];
            [coverFlow setDomainType:self.domainType];
            [coverFlow setCoverViewDelegate:self];
            [coverFlow loadData];
            self.homeFeatureTagPSColeectionView.headerView =coverFlow;
        }
        
        //Add a footer view
        CGRect loadingRect  = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*30/320);
        FlyingLoadingView* loadingView = [[FlyingLoadingView alloc] initWithFrame:loadingRect];
        loadingView.loadingViewDelegate=self;
        self.homeFeatureTagPSColeectionView.footerView = loadingView;
        
        [self.view addSubview:self.homeFeatureTagPSColeectionView];
        
        _currentData = [NSMutableArray new];
        _currentLodingIndex=0;
        _maxNumOfTags=NSIntegerMax;
        
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refreshNow:) forControlEvents:UIControlEventValueChanged];
        [self.homeFeatureTagPSColeectionView addSubview:_refreshControl];
    }
    else
    {
        [(FlyingCoverView*)self.homeFeatureTagPSColeectionView.headerView loadData];
        [(FlyingLoadingView*)self.homeFeatureTagPSColeectionView.footerView showTitle:nil];
        
        [_currentData removeAllObjects];
        _currentLodingIndex=0;
        _maxNumOfTags=NSIntegerMax;
    }
    
    [self downloadMore];
}

- (void)refreshNow:(UIRefreshControl *)refreshControl
{
    if ([AFNetworkReachabilityManager sharedManager].reachable) {
        
        _refresh=YES;
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"刷新中..."];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self reloadAll];
        });
    }
    else
    {
        [_refreshControl endRefreshing];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Download data from Learning center
//////////////////////////////////////////////////////////////

- (BOOL)downloadMore
{
    if (_currentData.count<_maxNumOfTags)
    {
        _currentLodingIndex++;
                
        [FlyingHttpTool getAlbumListForDomainID:self.domainID
                                     DomainType:self.domainType
                                    ContentType:nil
                                   PageNumber:_currentLodingIndex
                                    OnlyRecommend:YES
                                   Completion:^(NSArray *albumList,NSInteger allRecordCount) {
                                       [self.currentData addObjectsFromArray:albumList];
                                       
                                       _maxNumOfTags=allRecordCount;
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self finishLoadingData];
                                       });
                                   }];
        
        return true;
    }
    else{
        
        return false;
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
        [self.homeFeatureTagPSColeectionView reloadData];
    }
    
    //处理footview
    if (_currentData.count>=_maxNumOfTags) {
        
        FlyingLoadingView * loadingView= (FlyingLoadingView*)self.homeFeatureTagPSColeectionView.footerView;
        if (loadingView)
        {
            [loadingView showTitle:@"点击右上角搜索更多内容!"];
        }
    }
    else
    {
        FlyingLoadingView * loadingView= (FlyingLoadingView*)self.homeFeatureTagPSColeectionView.footerView;
        
        if(_currentData.count==0)
        {
            if (loadingView)
            {
                [loadingView showTitle:@"没有更多内容！"];
            }
        }
        else
        {
            if (loadingView)
            {
                [loadingView showTitle:@"加载更多内容"];
            }
        }
    }
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
        
        //[self.messegerLabel  setText:@"没有内容"];
        return nil;
    }
    
    FlyingCoverViewCell *v = (FlyingCoverViewCell *)[self.homeFeatureTagPSColeectionView dequeueReusableViewForClass:[FlyingCoverViewCell class]];
    if (!v) {
        v = [[FlyingCoverViewCell alloc] initWithFrame:CGRectZero];
    }
    
    [v collectionView:self.homeFeatureTagPSColeectionView fillCellWithObject:[_currentData objectAtIndex:index] atIndex:index];
    
    [v setMiniShadow];
    
    return v;
}

- (CGFloat)collectionView:(PSCollectionView *)collectionView heightForRowAtIndex:(NSInteger)index
{
    FlyingCoverData* coverData = [_currentData objectAtIndex:index];
    return  [FlyingCoverViewCell  rowHeightForObject:coverData inColumnWidth:self.homeFeatureTagPSColeectionView.colWidth];
}

- (void)collectionView:(PSCollectionView *)collectionView didSelectCell:(PSCollectionViewCell *)cell atIndex:(NSInteger)index
{
    if (_currentData.count!=0) {
        
        FlyingCoverData* coverData = [_currentData objectAtIndex:index];
        
        FlyingContentListVC * list=[[FlyingContentListVC alloc] init];
        [list setTagString:coverData.tagString];
        [list setContentType:coverData.tagtype];
        [list setDomainID:self.domainID];
        [list setDomainType:self.domainType];
        
        [self.navigationController pushViewController:list animated:YES];
    }
}

//////////////////////////////////////////////////////////////
#pragma FlyingCoverViewDelegate Related
//////////////////////////////////////////////////////////////
- (void) touchCover:(FlyingPubLessonData*)lessonPubData
{
    FlyingContentVC *contentVC = [[FlyingContentVC alloc] init];
    [contentVC setThePubLesson:lessonPubData];
    
    [self pushViewController:contentVC animated:YES];
}

- (void) showFeatureContent
{
    FlyingContentListVC *contentList = [[FlyingContentListVC alloc] init];
    [contentList setIsOnlyFeatureContent:YES];
    [contentList setDomainID:self.domainID];
    [contentList setDomainType:self.domainType];
    [self pushViewController:contentList animated:YES];
}

- (void) pushViewController:(UIViewController *)viewController animated:(BOOL) animated
{
    [self.navigationController pushViewController:viewController animated:animated];
}

@end
