//
//  FlyingEnglish
//
//  Created by vincent on 9/4/15.
//  Copyright (c) 2015 BirdEngish. All rights reserved.
//

#import "FlyingContentListVC.h"
#import "FlyingHttpTool.h"
#import "FlyingConversationListVC.h"
#import "FlyingConversationVC.h"
#import "UICKeyChainStore.h"
#import "shareDefine.h"
#import "FlyingDiscoverVC.h"
#import <AFNetworking/AFNetworking.h>
#import "iFlyingAppDelegate.h"
#import <RongIMKit/RongIMKit.h>
#import <RongIMLib/RongIMLib.h>
#import "RCDataBaseManager.h"
#import "UICKeyChainStore.h"
#import "NSString+FlyingExtention.h"
#import "FlyingNavigationController.h"
#import "FlyingDataManager.h"
#import "FlyingContentVC.h"
#import "FlyingContentListVC.h"
#import "FlyingContentCell.h"
#import "FlyingPubLessonData.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "FlyingSearchViewController.h"
#import "FlyingWebViewController.h"

@interface FlyingContentListVC ()<UIViewControllerRestoration>
{
    NSInteger            _maxNumOfContents;
    NSInteger            _currentLodingIndex;
}

@property (nonatomic,strong) YALSunnyRefreshControl *sunnyRefreshControl;
@property (atomic,assign)    BOOL refresh;

@end

@implementation FlyingContentListVC

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
    
    //更新欢迎语言
    self.title =@"内容列表";
    if (self.tagString) {
        
        self.title=self.tagString;
    }
    
    //顶部右上角导航
    UIButton* searchButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [searchButton setBackgroundImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(doSearch) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* searchBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:searchButton];
    
    self.navigationItem.rightBarButtonItem = searchBarButtonItem;
    
    [self reloadAll];
    
    [self setupRefreshControl];
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

//////////////////////////////////////////////////////////////
#pragma mark socail Related
//////////////////////////////////////////////////////////////
- (void) doSearch
{
    FlyingSearchViewController * search=[[FlyingSearchViewController alloc] init];
    
    search.domainID = self.domainID;
    search.domainType = self.domainType;
    
    [self.navigationController pushViewController:search animated:YES];
}

//////////////////////////////////////////////////////////////
#pragma mark - Loading data and setup view
//////////////////////////////////////////////////////////////

- (void)reloadAll
{
    if (!self.contentTableView)
    {
        self.contentTableView = [[UITableView alloc] initWithFrame: CGRectMake(0.0f, 0, CGRectGetWidth(self.view.frame),CGRectGetHeight(self.view.frame)) style:UITableViewStylePlain];
        
        //必须在设置delegate之前
        UINib *nib = [UINib nibWithNibName:@"FlyingContentCell" bundle: nil];
        [self.contentTableView registerNib:nib  forCellReuseIdentifier:@"FlyingContentCell"];
        
        self.contentTableView.delegate = self;
        self.contentTableView.dataSource = self;
        self.contentTableView.backgroundColor = [UIColor clearColor];
        
        self.contentTableView.tableFooterView = [UIView new];
        
        
        self.contentTableView.restorationIdentifier = self.restorationIdentifier;
        
        if(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_1)
        {
            self.contentTableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        
        [self.view addSubview:_contentTableView];
        
        _currentData = [NSMutableArray new];
        
        _currentLodingIndex=0;
        _maxNumOfContents=NSIntegerMax;
    }

    [_currentData removeAllObjects];
    _currentLodingIndex=0;
    _maxNumOfContents=NSIntegerMax;
    
    [self loadMore];
}

# pragma mark - YALSunyRefreshControl methods

-(void)setupRefreshControl
{
    _refresh = NO;
    self.sunnyRefreshControl = [YALSunnyRefreshControl new];
    self.sunnyRefreshControl.delegate = self;
    [self.sunnyRefreshControl attachToScrollView:self.contentTableView];
}

-(void)beginRefreshing
{
    if (_refresh)
    {
        return;
    }
    
    // start loading something
    if ([AFNetworkReachabilityManager sharedManager].reachable)
    {
        _refresh=YES;
        [self reloadAll];
    }
    else
    {
        [self endAnimationHandle];
    }
}

-(void)endAnimationHandle
{
    [self.sunnyRefreshControl endRefreshing];
    _refresh=NO;
}

//////////////////////////////////////////////////////////////
#pragma mark - Download data from Learning center
//////////////////////////////////////////////////////////////

- (void)loadMore
{
    if (_currentData.count<_maxNumOfContents)
    {
        _currentLodingIndex++;
        
        if (self.isOnlyFeatureContent)
        {
            [FlyingHttpTool getCoverListForDomainID:self.domainID
                                         DomainType:self.domainType
                                      PageNumber:_currentLodingIndex
                                      Completion:^(NSArray *lessonList,NSInteger allRecordCount) {
                                          //
                                          if (lessonList) {
                                              [self.currentData addObjectsFromArray:lessonList];
                                          }
                                          
                                          _maxNumOfContents=allRecordCount;
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self finishLoadingData];
                                          });
                                      }];
        }
        else
        {
            [FlyingHttpTool getLessonListForDomainID:self.domainID
                                          DomainType:self.domainType
                                       PageNumber:_currentLodingIndex
                                lessonConcentType:self.contentType
                                     DownloadType:self.downloadType
                                              Tag:self.tagString
                                        OnlyRecommend:self.isOnlyFeatureContent
                                       Completion:^(NSArray *lessonList, NSInteger allRecordCount) {
                                           //
                                           if (lessonList) {
                                               [self.currentData addObjectsFromArray:lessonList];
                                           }
                                           
                                           _maxNumOfContents=allRecordCount;
                                           
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
        [self endAnimationHandle];
    }
    
    //更新界面
    if (_currentData.count>0)
    {
        [self.contentTableView reloadData];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - UITableView Datasource
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.currentData.count && _currentData.count<_maxNumOfContents)
    {
        return 2; // 增加一个加载更多
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [self.currentData count];
    }
    
    // 加载更多
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        // 普通Cell
        FlyingContentCell* cell = [tableView dequeueReusableCellWithIdentifier:@"FlyingContentCell"];
        
        if (!cell) {
            
            cell = [FlyingContentCell contentCell];
        }
        
        [self configureCell:cell atIndexPath:indexPath];

        return cell;
    }
    
    // 加载更多
    static NSString *CellIdentifierLoadMore = @"CellIdentifierLoadMore";
    
    UITableViewCell *loadCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierLoadMore];
    if (!loadCell)
    {
        loadCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierLoadMore];
        loadCell.backgroundColor = [UIColor clearColor];
        loadCell.contentView.backgroundColor = [UIColor clearColor];
        
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.tag = kLoadMoreIndicatorTag;
        indicator.hidesWhenStopped = YES;
        indicator.center =loadCell.center;
        indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|
        UIViewAutoresizingFlexibleRightMargin|
        UIViewAutoresizingFlexibleTopMargin|
        UIViewAutoresizingFlexibleBottomMargin;
        [loadCell.contentView addSubview:indicator];
    }
        
    return loadCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        // 普通Cell的高度
        return [tableView fd_heightForCellWithIdentifier:@"FlyingContentCell"
                                        cacheByIndexPath:indexPath
                                           configuration:^(id cell) {
            
            [self configureCell:cell atIndexPath:indexPath];
        }];
    
    }
    
    // 加载更多
    return 44;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FlyingPubLessonData *contentData = self.currentData[indexPath.row];
    [(FlyingContentCell*)cell settingWithContentData:contentData];
}
//////////////////////////////////////////////////////////////
#pragma mark - UITableView Delegate methods
//////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return;
    }
    
    // 加载更多
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:kLoadMoreIndicatorTag];
    [indicator startAnimating];
    
    // 加载下一页
    [self loadMore];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return;
    }
    
    // 加载更多
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:kLoadMoreIndicatorTag];
    [indicator stopAnimating];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_currentData.count!=0) {
        
        FlyingPubLessonData* lessonPubData = [_currentData objectAtIndex:indexPath.row];
        
        if ([lessonPubData.contentType isEqualToString:KContentTypePageWeb] ) {
            
            FlyingWebViewController * webVC=[[FlyingWebViewController alloc] init];
            [webVC setThePubLesson:lessonPubData];
            
            [self.navigationController pushViewController:webVC animated:YES];
        }
        else
        {
            FlyingContentVC *contentVC = [[FlyingContentVC alloc] init];
            [contentVC setThePubLesson:lessonPubData];
            
            [self.navigationController pushViewController:contentVC animated:YES];
        }
    }
}

@end
