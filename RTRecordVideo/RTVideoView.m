//
//  RTVideoView.m
//  RTRecordVideo
//
//  Created by RongTian on 13-11-4.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import "RTVideoView.h"

#import <QuartzCore/QuartzCore.h>
#define SCREENWIDTH   [[UIScreen mainScreen]applicationFrame].size.width

@interface RTVideoView ()

- (void)addUI;

- (void)setLabelTimeV;
@end

@implementation RTVideoView
@synthesize labelTime = _labelTime;
@synthesize changeCameraBtn = _changeCameraBtn;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self addUI];
    }
    return self;
}

#pragma mark - 
#pragma mark 添加页面UI
- (void)addUI
{
    // LodingView
    float loding_Size = [[UIScreen mainScreen]applicationFrame].size.height - 20;
    self.busyView = [[UIView alloc]initWithFrame:CGRectMake(0, 0 - loding_Size, 320, loding_Size)];
    [self addSubview:self.busyView];


    // ========================================= video展示View =====================================================================
    self.videoPreviewView = [[ UIView alloc]initWithFrame:CGRectMake(0, -20, 320, [[UIScreen mainScreen] applicationFrame].size.height + 20 - 44)];
    self.videoPreviewView.backgroundColor = [UIColor whiteColor];
    [self addSubview: self.videoPreviewView];
    
    
    // ========================================= 下部导航 =============================================================================
    UIImageView *bottomVew = [[UIImageView alloc]initWithFrame:CGRectMake(0, [[UIScreen mainScreen]applicationFrame].size.height - 44, 320, 44)];
    bottomVew.backgroundColor = [UIColor blackColor];
    bottomVew.userInteractionEnabled = YES;
    [self addSubview:bottomVew];
    
    
    // ========================================= 开始录制UIbutton =====================================================================
    UIButton *startRecordVideo = [UIButton buttonWithType:UIButtonTypeCustom];
    [startRecordVideo setImage:[UIImage imageNamed:@"RT_startRecord"] forState:UIControlStateNormal];
    startRecordVideo.frame = CGRectMake(((float)SCREENWIDTH - 82)/2, 2, 82, 40) ;
    [startRecordVideo addTarget:self.superview action:@selector(startRecord:) forControlEvents:UIControlEventTouchUpInside];
    [bottomVew addSubview:startRecordVideo];    
    
    
   
    // ========================================= 取消录制 dismiss RecordViewController ===============================================
    _cancelRecordVideo = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelRecordVideo setImage:[UIImage imageNamed:@"RT_closeCordVideo.png"] forState:UIControlStateNormal];
    _cancelRecordVideo.frame = CGRectMake(5, -10, 46, 73) ;
    [_cancelRecordVideo addTarget:self.superview action:@selector(cancelRecord:) forControlEvents:UIControlEventTouchUpInside];
    [bottomVew addSubview:_cancelRecordVideo];


    // ========================================= 录制视频的timeLabel =================================================================
    [self setLabelTimeV];

    // ========================================= 前后摄像头的切换 ====================================================================
    self.changeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.changeCameraBtn.frame = CGRectMake((float)SCREENWIDTH - 100 + 15, -12, 100, 73);
    [self.changeCameraBtn setImage:[UIImage imageNamed:@"RT_capture_change.png"] forState:UIControlStateNormal];
    [self.changeCameraBtn addTarget:self.superview action:@selector(changeCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomVew addSubview:self.changeCameraBtn];

}

#pragma mark 录制视频的时间
- (void)setLabelTimeV
{
    // 250, 0, 60, 40
    self.labelTime = [[UILabel alloc]initWithFrame:CGRectMake((float)SCREENWIDTH - 44, 0, 35, 25)];
    self.labelTime.backgroundColor = [UIColor grayColor];
    self.labelTime.textAlignment = NSTextAlignmentCenter;
    self.labelTime.layer.masksToBounds = YES;  // 隐藏边界
    self.labelTime.layer.cornerRadius = 8.0;  // 设置layer圆角半径
    [self.labelTime setFont:[UIFont fontWithName:@"DBLCDTempBlack" size:21.0]];
     self.labelTime.text= @"15s";
    self.labelTime.textColor = [UIColor whiteColor];
//    [self.videoPreviewView addSubview:self.labelTime];
    [self addSubview:self.labelTime];
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
