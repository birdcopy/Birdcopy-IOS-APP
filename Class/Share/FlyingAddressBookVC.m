//
//  FlyingEnglish
//
//  Created by BE_Air on 6/20/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//

#import "FlyingAddressBookVC.h"
#import "NSString+FlyingExtention.h"
#import "shareDefine.h"
#import "FlyingHttpTool.h"
#import "FlyingGroupMemberData.h"
#import "FlyingAddressBookTableViewCell.h"
#import "iFlyingAppDelegate.h"
#import "FlyingDataManager.h"
#import "FlyingProfileVC.h"
#import <RongIMLib/RongIMLib.h>
#import "RCDataBaseManager.h"
#import "FlyingGroupVC.h"
#import "FlyingSoundPlayer.h"

static NSString * const kFKRSearchBarTableViewControllerDefaultTableViewCellIdentifier = @"kFKRSearchBarTableViewControllerDefaultTableViewCellIdentifier";

@interface FlyingAddressBookVC ()<UISearchResultsUpdating,
                                    UISearchBarDelegate,
                                    UIViewControllerRestoration>

@property (strong, nonatomic) UITableView         *tableView;

@property (strong, nonatomic) UISearchController    *searchController;
@property (nonatomic, retain) NSMutableArray        *searchResults;
@property (nonatomic, retain) NSOperationQueue      *searchQueue;

@property (nonatomic, retain) NSArray               *memberNameList;
@property (nonatomic, retain) NSMutableDictionary   *allMemberDic;

@property (strong, nonatomic) NSString          *searchStringForCurrentResult;
@property (nonatomic, retain) NSString          *defaultShowStr;


@end

@implementation FlyingAddressBookVC

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                                                            coder:(NSCoder *)coder
{
    UIViewController *vc = [self new];
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    if (![self.title isBlankString])
    {
        [coder encodeObject:self.title forKey:@"self.title"];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    NSString * string = [coder decodeObjectForKey:@"self.title"];
    
    if (![string isBlankString])
    {
        self.title = string;
    }
}

- (id)init
{
    if ((self = [super init]))
    {
        // Custom initialization
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        self.tableView.restorationIdentifier = self.restorationIdentifier;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    //顶部导航
    UIButton* membershipButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [membershipButton setBackgroundImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [membershipButton addTarget:self action:@selector(joinMembership) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* membershipBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:membershipButton];
    
    self.navigationItem.rightBarButtonItem= membershipBarButtonItem;

    [self commonInit];
}

- (void) commonInit
{
    //顶部导航
    if (!self.searchController) {

        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
    }
    
    if (!self.tableView) {

        self.tableView = [[UITableView alloc] initWithFrame: CGRectMake(0.0f, 0, CGRectGetWidth(self.view.frame),CGRectGetHeight(self.view.frame)) style:UITableViewStylePlain];
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        self.tableView.tableHeaderView = self.searchController.searchBar;
        [self.view addSubview:self.tableView];
    }
    
    self.definesPresentationContext = YES;
    
    //初始化相关数据
    [self loadData];
}

- (void)loadData
{
    self.defaultShowStr = @"没有查询结果";
    self.searchController.searchBar.placeholder = @"请输入昵称";
    
    self.searchResults = [NSMutableArray array];
    self.allMemberDic = [NSMutableDictionary new];
    
    self.searchQueue = [NSOperationQueue new];
    [self.searchQueue setMaxConcurrentOperationCount:1];
    
    
    [self getAllMemberListForForDomainID:self.domainID
                              DomainType:self.domainType];
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

-(RCUserInfo*) getUserIofo:(NSIndexPath *)indexPath
{
    NSString *name = [_searchResults objectAtIndex:indexPath.row];
    
    if ([[_allMemberDic objectForKey:name] isKindOfClass:[FlyingGroupMemberData class]]) {
        
        FlyingGroupMemberData * groupMemberData = (FlyingGroupMemberData *)[_allMemberDic objectForKey:name];
        
        RCUserInfo * result = [RCUserInfo new];
        
        result.userId = [groupMemberData.openUDID MD5];
        result.name = [groupMemberData name];
        result.portraitUri = [groupMemberData portrait_url];
        
        return result;
    }
    
    else if ([[_allMemberDic objectForKey:name] isKindOfClass:[RCUserInfo class]]) {
     
        return [_allMemberDic objectForKey:name];
    }
    
    return nil;
}

-(void) setallowsMultipleSelection:(BOOL) allowsMultipleSelection
{
    self.tableView.allowsMultipleSelection = allowsMultipleSelection;
}


-(NSArray*) indexPathsForSelectedRows
{
    return  [self.tableView indexPathsForSelectedRows];
}

-(void) joinMembership
{
    //暂时不支持非群组成员申请
    if (![BC_Domain_Group isEqualToString:self.domainType]) {
        
        return;
    }
    
    [self applyingMembership:self.domainID];
}

- (void) applyingMembership:(NSString*)groupID
{
    [FlyingGroupVC doMemberRightInVC:self
                             GroupID:groupID
                          Completion:^(FlyingUserRightData *userRightData) {
                              //即时反馈
                              iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
                              NSString * message = [userRightData getMemberStateInfo];
                              [appDelegate makeToast:message];
                          }];
    
}

//////////////////////////////////////////////////////////////
#pragma mark - Download data from Learning center
//////////////////////////////////////////////////////////////
- (void)getAllMemberListForForDomainID:(NSString*)domainID
                          DomainType:(NSString*) domainType
{
    if ([domainType isEqualToString:BC_Domain_Business]) {
        //所有会员
    }
    else if([domainType isEqualToString:BC_Domain_Group])
    {
        [FlyingHttpTool getMemberListForGroupID:self.domainID
                                     Completion:^(NSArray *memberList, NSInteger allRecordCount) {
                                         
                                         //
                                         if (memberList) {
                                             
                                             [memberList enumerateObjectsUsingBlock:^(FlyingGroupMemberData* obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                 
                                                 if (obj.name)
                                                 {
                                                     
                                                     [self.allMemberDic setObject:obj forKey:[NSString transformToPinyin:obj.name]];
                                                 }
                                             }];
                                         }
                                         
                                         self.memberNameList = [self.allMemberDic allKeys];
                                         
                                         [self.searchResults removeAllObjects];
                                         [self.searchResults addObjectsFromArray:self.memberNameList];
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [self.tableView  reloadData];
                                         });
                                     }];

    }
    else if ([domainType isEqualToString:BC_Domain_Author])
    {
        //个人粉丝
    }
    else
    {
        NSArray * conversationList = [[RCIMClient sharedRCIMClient] getConversationList:@[@(ConversationType_PRIVATE)]];
        
        
        [conversationList enumerateObjectsUsingBlock:^(RCConversation* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //
            
            RCUserInfo *userInfo=[[RCDataBaseManager shareInstance] getUserByUserId:obj.targetId];

            [self.allMemberDic setObject:userInfo forKey:userInfo.name];
        }];
        
        self.memberNameList = [self.allMemberDic allKeys];
        
        [self.searchResults removeAllObjects];
        [self.searchResults addObjectsFromArray:self.memberNameList];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView  reloadData];
        });
    }
}

- (void)handleError:(NSError *)error
{
    
    self.title = self.defaultShowStr;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) dealWtihTapString:(NSString *) resultString
{
    if (![resultString isEqualToString:self.defaultShowStr])
    {
        
        FlyingUserRightData * userRightData = [FlyingDataManager getUserRightForDomainID:self.domainID domainType:self.domainType];
        
        //合格会员，直接查看会员
        if ([userRightData checkRightPresent]) {
            
            FlyingProfileVC* profileVC = [[FlyingProfileVC alloc] init];
            
            FlyingGroupMemberData * groupMemberData = (FlyingGroupMemberData *)[_allMemberDic objectForKey:resultString];
            profileVC.openUDID = groupMemberData.openUDID;
                        
            [self.navigationController pushViewController:profileVC animated:YES];
        }
        //非合格会员，不能查看会员
        else
        {
            //即时反馈
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSString * message = [userRightData getMemberStateInfo];
            [appDelegate makeToast:message];
        }
    }
}

#pragma mark - TableView Delegate and DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 普通Cell
    FlyingAddressBookTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"FlyingAddressBookTableViewCell"];
    
    if (!cell) {
        cell = [FlyingAddressBookTableViewCell adressBookCell];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [(FlyingAddressBookTableViewCell*)cell settingWithContentData:[self getUserIofo:indexPath]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(INTERFACE_IS_PAD){
        
        return 52;
    }
    else{
        
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString * key=(NSString *)[_searchResults objectAtIndex:indexPath.row];
    
    if (key) {
        
        [self dealWtihTapString:key];
    }
}

#pragma mark - Search Delegate
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar __TVOS_PROHIBITED;   // called when cancel button pressed
{
    
    [self.searchQueue cancelAllOperations];
    
    [_searchResults removeAllObjects];
    [_searchResults addObjectsFromArray:_memberNameList];
    
    _searchStringForCurrentResult = @"";
    
    [self refreshSearchResult];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
    NSString *searchString = searchController.searchBar.text;
    
    BOOL refreshResult =NO;
    
    if  (searchString.length==0)
    {
        
        if (_searchResults.count==_memberNameList.count) {
            
            refreshResult = NO;
        }
        else
        {
            [_searchResults removeAllObjects];
            [_searchResults addObjectsFromArray:_memberNameList];
            
            refreshResult = YES;
        }
    }
    else
    {
        if (_searchStringForCurrentResult.length > 0 && [searchString rangeOfString:_searchStringForCurrentResult].location == 0) {
            // If the new search string starts with the last search string, reuse the already filtered array so searching is faster
            
            NSArray * resultsToReuse = _searchResults;
            
            NSArray *results = [resultsToReuse filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchString]];
            
            [self.searchResults removeAllObjects];
            
            if (results.count!=0) {
                
            }
            else
            {
                [self.searchResults addObjectsFromArray:results];
            }
            
            refreshResult = YES;
        }
        else
        {
            [self.searchQueue cancelAllOperations];
            
            NSArray * resultsToReuse = _memberNameList;
            NSArray *results = [resultsToReuse filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchString]];
            
            [self.searchResults removeAllObjects];
            
            if (results.count!=0) {
                
                refreshResult = YES;
                
                [self.searchResults addObjectsFromArray:results];
            }
            else
            {
                refreshResult = NO;
            }
        }
    }
    
    if (refreshResult) {
        
        _searchStringForCurrentResult = searchString;
        
        [self refreshSearchResult];
    }
}

-(void) refreshSearchResult
{
    
    [self.tableView reloadData];
}

#pragma only portart events
//////////////////////////////////////////////////////////////
-(BOOL)shouldAutorotate
{
    return NO;
}

@end
