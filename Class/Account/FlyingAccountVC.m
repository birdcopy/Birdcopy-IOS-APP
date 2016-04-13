//
//  FlyingAccountVC.m
//  FlyingEnglish
//
//  Created by vincent on 5/25/15.
//  Copyright (c) 2015 BirdEngish. All rights reserved.
//

#import "FlyingAccountVC.h"
#import "UIColor+RCColor.h"
#import "iFlyingAppDelegate.h"
#import "FlyingProfileVC.h"
#import "FlyingNavigationController.h"
#import "FlyingHttpTool.h"
#import "UICKeyChainStore.h"
#import "FlyingPickColorVCViewController.h"
#import <RongIMKit/RCIM.h>
#import "shareDefine.h"
#import "NSString+FlyingExtention.h"
#import <UIImageView+AFNetworking.h>
#import "UIView+Toast.h"
#import "AFHttpTool.h"
#import "FlyingNowLessonDAO.h"
#import "FlyingNowLessonData.h"
#import "FlyingLessonDAO.h"
#import "FlyingLessonData.h"
#import "MKStoreKit.h"
#import "FlyingDataManager.h"
#import "FlyingHttpTool.h"
#import "FlyingConversationListVC.h"
#import "FlyingDataManager.h"
#import "FlyingWebViewController.h"
#import "FlyingUserRightData.h"
#import "FlyingReviewVC.h"
#import "FlyingConversationVC.h"
#import "FlyingTaskWordDAO.h"
#import "FlyingBuyVC.h"
#import "FlyingImageTextCell.h"
#import "FlyingMessageNotifySettingVC.h"

@interface FlyingAccountVC ()<UITableViewDataSource,
                                UITableViewDelegate,
                                UIViewControllerRestoration>
{
    NSInteger _wordCount;
}

@property (strong, nonatomic) UITableView        *tableView;

@end

@implementation FlyingAccountVC

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
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.000];
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self addBackFunction];
    
    self.restorationIdentifier = NSStringFromClass([self class]);
    self.restorationClass = [self class];

    //标题
    self.title = NSLocalizedString(@"Account",nil);

    //顶部导航
    if(self.navigationController.viewControllers.count>1)
    {
        UIButton* backButton= [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
        [backButton setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(dismissNavigation) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem* backBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:backButton];
        self.navigationItem.leftBarButtonItem = backBarButtonItem;
    }
    
    [self reloadAll];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:KBEAccountChange
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [self updateProflie];
                                                      //[self.tableView reloadData];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:KBELocalCacheClearOK
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [self.view makeToast:NSLocalizedString(@"Cleanning is ok",nil)
                                                                  duration:1
                                                                  position:CSToastPositionCenter];
                                                  }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KBEAccountChange    object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KBELocalCacheClearOK    object:nil];
}

- (void) dismissNavigation
{
    [self willDismiss];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) willDismiss
{
}

//////////////////////////////////////////////////////////////
#pragma mark - Loading data and setup view
//////////////////////////////////////////////////////////////

- (void)reloadAll
{
    if (!self.tableView)
    {
        self.tableView = [[UITableView alloc] initWithFrame: CGRectMake(0.0f, 0, CGRectGetWidth(self.view.frame),CGRectGetHeight(self.view.frame)) style:UITableViewStylePlain];
        
        //必须在设置delegate之前
        [self.tableView registerNib:[UINib nibWithNibName:@"FlyingImageTextCell" bundle:nil]
             forCellReuseIdentifier:@"FlyingImageTextCell"];
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.backgroundColor = [UIColor clearColor];
        //self.tableView.separatorColor = [UIColor clearColor];
        
        //self.tableView.tableFooterView = [UIView new];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];

        
        [self.view addSubview:self.tableView];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - UITableView Datasource
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    else if (section == 1)
    {
        return 1;
    }
    else if (section == 2)
    {
        return 1;
    }
    else if (section == 3)
    {
        return 3;
    }
    else if (section == 4)
    {
        return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    
    FlyingImageTextCell *profileTabelViewCell = [tableView dequeueReusableCellWithIdentifier:@"FlyingImageTextCell"];
    
    if(profileTabelViewCell == nil)
        profileTabelViewCell = [FlyingImageTextCell imageTextCell];
    
    [self configureCell:profileTabelViewCell atIndexPath:indexPath];
    
    cell = profileTabelViewCell;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 47.5;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        
        FlyingUserData *userData=[FlyingDataManager getUserData:nil];
        
        if (![userData.portraitUri isBlankString]){
            [(FlyingImageTextCell *)cell setImageIconURL:userData.portraitUri];
        }
        else{
            
            if (![FlyingDataManager getOpenUDID]) {
                
                return;
            }
            
            [FlyingHttpTool getUserInfoByopenID:[FlyingDataManager getOpenUDID]
                                     completion:^(FlyingUserData *userData, RCUserInfo *userInfo) {
                                         //
                                         if ([userData.portraitUri isBlankString]) {
                                             
                                             [self.view makeToast:NSLocalizedString(@"Touch portrait to update it!", nil)
                                                         duration:1
                                                         position:CSToastPositionCenter];
                                         }
                                         else
                                         {
                                             [(FlyingImageTextCell *)cell setImageIconURL:userData.portraitUri];
                                             [(FlyingImageTextCell *)cell setCellText:userData.name];
                                         }
                                         
                                     }];
        }
        
        if (![userData.name isBlankString]){
            
            [(FlyingImageTextCell *)cell setCellText:userData.name];
        }
        else{
            
            [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Touch nickName to update it!", nil)];
        }
    }
    
    else if (indexPath.section == 1)
    {
        [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"Price"]];
        [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"My Service",nil)];
    }
    
    else if (indexPath.section == 2)
    {
        NSString * englishLabel = NSLocalizedString(@"English Tool",nil);

        NSArray *wordArray =  [[[FlyingTaskWordDAO alloc] init] selectWithUserID:[FlyingDataManager getOpenUDID]];
        _wordCount = wordArray.count;
        if (_wordCount>0) {
            
            englishLabel= [NSString stringWithFormat:NSLocalizedString(@"Scene Dictionary[%@]", nil) , @(_wordCount)];
        }
        
        [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"Word"]];
        [(FlyingImageTextCell *)cell setCellText:englishLabel];
    }
    
    else if (indexPath.section == 3)
    {
        
        switch (indexPath.row) {
            case 0:
            {
                [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"chat"]];
                [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Chat Setting",nil)];
                break;
            }
                
            case 1:
            {
                [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"close"]];
                [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Clear Cache",nil)];
                break;
            }
                
            case 2:
            {
                [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"colorWheel"]];
                [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Style Setting",nil)];
                break;
            }
                
            default:
                break;
        }
    }
    else if (indexPath.section == 4)
    {
        [(FlyingImageTextCell *)cell setImageIcon:[UIImage imageNamed:@"Help"]];
        [(FlyingImageTextCell *)cell setCellText:NSLocalizedString(@"Service Online",nil)];
    }
}

- (void) updateProflie
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            FlyingProfileVC* profileVC = [[FlyingProfileVC alloc] init];
            
            profileVC.openUDID = [FlyingDataManager getOpenUDID];
            profileVC.hidesBottomBarWhenPushed = YES;
            
            [self.navigationController pushViewController:profileVC animated:YES];

            break;
        }
            
        case 1:
        {
            FlyingBuyVC * buyVC = [[FlyingBuyVC alloc] init];
            
            buyVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:buyVC animated:YES];

            break;
        }
            
        case 2:
        {
            if (_wordCount>0) {
                
                FlyingReviewVC * reviewVC = [[FlyingReviewVC alloc] init];
                reviewVC.hidesBottomBarWhenPushed = YES;
                
                [self.navigationController pushViewController:reviewVC animated:YES];
            }
            else
            {
                [self.view makeToast:NSLocalizedString(@"Touch subtitle and learn there!", nil)
                            duration:3
                            position:CSToastPositionCenter];
            }

            break;
        }
            
        case 3:
        {
            if (indexPath.row == 0)
            {
                FlyingMessageNotifySettingVC * notifySettingVC = [[FlyingMessageNotifySettingVC alloc] init];
                notifySettingVC.hidesBottomBarWhenPushed = YES;

                [self.navigationController pushViewController:notifySettingVC animated:YES];
            }
            else if (indexPath.row == 1) {
                
                [self clearCache];
            }
            else if (indexPath.row == 2) {
                
                
                FlyingPickColorVCViewController * vc= [[FlyingPickColorVCViewController alloc] init];
                
                vc.hidesBottomBarWhenPushed = YES;
                //定制导航条背景颜色
                [self.navigationController pushViewController:vc animated:YES];
            }

            break;
        }
            
        case 4:
        {
            FlyingConversationVC *chatService = [[FlyingConversationVC alloc] init];
            
            chatService.domainID = self.domainID;
            chatService.domainType = self.domainType;
            
            chatService.targetId = self.domainID;
            chatService.conversationType = ConversationType_CHATROOM;
            chatService.title = NSLocalizedString(@"Service Online",nil);
            chatService.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:chatService animated:YES];

            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


//清理缓存
-(void) clearCache
{
    [FlyingDataManager clearCache];
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

- (void)viewDidDisappear:(BOOL)animated
{
    [self resignFirstResponder];
    [super viewDidDisappear:animated];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate shakeNow];
    }
}

- (void) addBackFunction
{
    //在一个函数里面（初始化等）里面添加要识别触摸事件的范围
    UISwipeGestureRecognizer *recognizer= [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizer];
}

-(void) handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer
{
    if(recognizer.direction==UISwipeGestureRecognizerDirectionRight) {
        
        [self dismissNavigation];
    }
}

@end
