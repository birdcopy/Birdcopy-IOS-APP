//
//  FlyingDiscoverContent.h
//  FlyingEnglish
//
//  Created by vincent on 9/5/15.
//  Copyright (c) 2015 BirdEngish. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "PSCollectionView.h"
#import "FlyingCoverView.h"
#import "FlyingLoadingView.h"
#import "FlyingViewController.h"

@interface FlyingDiscoverVC : FlyingViewController<FlyingCoverViewDelegate,
                                                    PSCollectionViewDataSource,
                                                    PSCollectionViewDelegate,
                                                    FlyingLoadingViewDelegate>

@property (strong, nonatomic) NSMutableArray     *currentData;
@property (strong, nonatomic) PSCollectionView   *homeFeatureTagPSColeectionView;
@property (strong, nonatomic) NSString           *domainID;
@property (assign, nonatomic) BC_Domain_Type      domainType;
@property (assign, nonatomic) BOOL               shoudLoaingFeature;

@end