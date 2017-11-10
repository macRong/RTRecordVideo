//
//  RTVideoView.h
//  RTRecordVideo
//
//  Created by RongTian on 13-11-4.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RTVideoView : UIView

// video展示的View
@property (nonatomic, strong) UIView         *videoPreviewView;
@property (nonatomic, strong) UIView         *busyView;

// 取消录制的按钮
@property (nonatomic, strong) UIButton        *cancelRecordVideo;

// 录制视频的timeLabel
@property (nonatomic, strong) UILabel         *labelTime;

// 前后摄像头的切换按钮
@property (nonatomic, strong) UIButton        *changeCameraBtn;

@end
