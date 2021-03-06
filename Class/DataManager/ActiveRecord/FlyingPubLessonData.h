//
//  FlyingPubLessonData.h
//  FlyingEnglish
//
//  Created by vincent sung on 1/21/13.
//  Copyright (c) 2013 vincent sung. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FlyingLessonData;

@interface FlyingPubLessonData : NSObject<NSCoding>

@property (nonatomic, strong) NSString *lessonID;
@property (nonatomic, strong) NSString *title;              //课程名称
@property (nonatomic, strong) NSString *desc;               //课程描述
@property (nonatomic, strong) NSString *imageURL;           //课程截图
@property (nonatomic, strong) NSString *contentURL;         //内容连接
@property (nonatomic, strong) NSString *subtitleURL;        //课程字幕
@property (nonatomic, strong) NSString *pronunciationURL;   //语音补丁
@property (nonatomic, strong) NSString *level;              //难度分布
@property (nonatomic, assign) NSInteger  duration;           //课程时长
@property (nonatomic, strong) NSString *contentType;        //资源类型
@property (nonatomic, strong) NSString *downloadType;       //下载类型
@property (nonatomic, strong) NSString *tag;                //标签
@property (nonatomic, assign) NSInteger coinPrice;          //标价
@property (nonatomic, strong) NSString *weburl;             //官方地址
@property (nonatomic, strong) NSString *ISBN;               //ISBN
@property (nonatomic, strong) NSString *relativeURL;        //内容辅助资源

@property (nonatomic, assign) BOOL     canDownloaded;       //是否可以下载

@property (nonatomic, strong) NSString *author;             //课程作者
@property (nonatomic, strong) NSString *timeLamp;           //更新时间戳
@property (nonatomic, strong) NSString *commentCount;       //评论数


- (id)initWithLessonData:(FlyingLessonData*) lessonData;
- (void) getValueFromLessonData:(FlyingLessonData*) lessonData;


-(void)encodeWithCoder:(NSCoder *)encoder;
-(id)  initWithCoder:(NSCoder *)decoder;

- (BOOL) isEqual:(id)object;


@end
