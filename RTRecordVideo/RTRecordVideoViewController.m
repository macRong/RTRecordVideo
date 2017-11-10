//
//  RTRecordVideoViewController.m
//  RTRecordVideo
//
//  Created by RongTian on 13-10-31.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import "RTRecordVideoViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import "RTVideoCameraInputManager.h"

#import "RTVideoView.h"

#import "RTPreviewVideoViewController.h"

@interface RTRecordVideoViewController (Private)

// 调用NSTimer
- (void)updateProgress:(NSTimer *)timer;
// 拿到videoURL处理
- (void)saveOutputToAssetLibrary:(NSURL *)outputFileURL completionBlock:(void (^)(NSError *error))completed;

// 添加UI
- (void)addUI;

// RecordVideo的处理
- (void)setRecordVideo;
// 保存录制的视频
- (void)saveRecordVideo;

// 获得录制视频的横竖屏
- (void)getDeviceOrientation;

// 保存录制视频时的横竖屏
- (void)saveRecordVideoSize:(float)record_width video_H:(float)record_height;

@end

// 设置录制视频的最长时间15s 以及最小时间2s
#define MAX_RECORDING_LENGTH            15.0
#define MIN_RECORDING_LENGTH            1.0

// 设置录制的分辨率
#define VIDEORENDER_HEIGHT              640.0f
#define VIDEORENDER_WIDTH               480.0f

// 设置录制视频所显示的分辨率  
#define CAPTURE_SESSION_PRESET          AVCaptureSessionPreset640x480

// 设置录制视频的前后摄像头   默认：后置摄像
#define INITIAL_CAPTURE_DEVICE_POSITION AVCaptureDevicePositionBack

// 设置录制视频是否要开启灯   默认：关闭
#define INITIAL_TORCH_MODE               AVCaptureTorchModeOff

//设置录制视频存放的videoName
#define VIDEOPATHNAME                    @"RTVIDEOCORD"

@implementation RTRecordVideoViewController
{
    RTVideoCameraInputManager    *videoCameraInputManager;
    
    RTVideoView                  *videoView;
    
    AVCaptureVideoPreviewLayer   *captureVideoPreviewLayer;
    
    NSTimer                      *progressUpdateTimer;
    
    int                          seconds;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
      [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // 添加UI
    [self addUI];
    
//    [self setRecordVideo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 隐藏StatusBar
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    
    // 设置录制视频
     [self setRecordVideo];
}

#pragma mark - 设置页面的UI
- (void)addUI
{
    seconds = 0;
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    videoView = [[RTVideoView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:videoView];
}

#pragma mark 开始录制
- (void)startRecord:(UIButton *)sender
{

    UIButton *recordBtn = (UIButton *)sender;
    if ([recordBtn.imageView.image isEqual:[UIImage imageNamed:@"RT_endRecord"]]) {

        
        [videoCameraInputManager pauseRecording];

        [self endTimer]; // 停止NSTimer

        [recordBtn setImage:[UIImage imageNamed:@"RT_startRecord"] forState:UIControlStateNormal];
        videoView.cancelRecordVideo.hidden = NO;   // 录制视频中 把取消的按钮显示
        videoView.changeCameraBtn.hidden = NO;
        // 延迟调用
        [self performSelector:@selector(saveRecord) withObject:nil afterDelay:2];
//         [self saveRecordVideo];  // ?
        NSLog(@"录制结束 ");
    }else if ([recordBtn.imageView.image isEqual:[UIImage imageNamed:@"RT_startRecord"]]) {
        [recordBtn setImage:[UIImage imageNamed:@"RT_endRecord"] forState:UIControlStateNormal];
        
        /* reset 方法主要是对录制多个视频 重新设置处理（暂时不加此功能）*/
        [videoCameraInputManager reset];  // ?
        
        [videoCameraInputManager startRecording];
        
        videoView.cancelRecordVideo.hidden = YES;   // 录制视频中 把取消的按钮隐藏
        videoView.changeCameraBtn.hidden = YES;
        
        progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                               target:self
                                                             selector:@selector(updateProgress:)
                                                             userInfo:nil
                                                              repeats:YES];
        [self getDeviceOrientation];
        
//        RTPreviewVideoViewController *previewVideo = [[RTPreviewVideoViewController alloc]init];
//        [self presentViewController:previewVideo animated:YES completion:^{
//            
//        }];
    }
}

- (void)saveRecord
{
    [self saveRecordVideo];
}

#pragma mark 切换前后摄像头
- (void)changeCameraAction:(UIButton *)sender
{
    [videoCameraInputManager changeFrontCamera ];
}

#pragma mark 获得录制视频时的横竖屏
- (void)getDeviceOrientation
{
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    
    float record_W , record_H;
    
    if (UIInterfaceOrientationIsLandscape(currentOrientation)) {
        record_W = VIDEORENDER_HEIGHT;
        record_H = VIDEORENDER_WIDTH;
        NSLog(@"+++++++++++++ 横屏录制 ++++++++++++");
    } else {
        record_W = VIDEORENDER_WIDTH;
        record_H = VIDEORENDER_HEIGHT;
         NSLog(@"+++++++++++++ 竖屏录制 ++++++++++++");
    }
    // 保存录制视频时的横竖屏
    [self saveRecordVideoSize:record_W video_H:record_H];
}

#pragma mark 保存录制视频时的横竖屏
- (void)saveRecordVideoSize:(float)record_width video_H:(float)record_height
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:record_width forKey:@"record_Width"];
    [defaults setFloat:record_height forKey:@"record_Hight"];
    [defaults synchronize];
}

#pragma mark 取消录制
- (void)cancelRecord:(UIButton *)sender
{
    NSLog(@"Cancel  dimmiss");
    
//     [videoCameraInputManager reset];

    [self saveRecordVideo];  // ?
    
    [self endTimer]; 
//    [self dismissViewControllerAnimated:YES completion:^{
//
//    }];
}

#pragma mark 秒表
- (void)updateProgress:(NSTimer *)timer
{
    NSLog(@"秒表的时间   %d",seconds++);

    CMTime duration = [videoCameraInputManager totalRecordingDuration];
    
    if (seconds >0 && seconds <= 15) {
        videoView.labelTime.text = [NSString stringWithFormat:@"%ds",15 - seconds];
        if (seconds == 15) {
            [self endTimer];
            return;
        }
    }
    NSLog(@"Curren Video Time = %f", CMTimeGetSeconds(duration) / MAX_RECORDING_LENGTH);
}

#pragma mark 录制结束
- (void)endTimer
{
    [progressUpdateTimer invalidate];
    progressUpdateTimer = nil;
}

#pragma mark 保存录制的视频到相册
- (void)saveRecordVideo
{
    // 如果是iphone5 ，4 在这里处理分辨率的大小
    CGSize videoSize = CGSizeMake(640, 480);

    [videoCameraInputManager finalizeRecordingToFile:[self returnRecordVideoPath]
                                       withVideoSize:videoSize
                                          withPreset:AVAssetExportPresetMediumQuality      // ? 改变录制视频的质量  文件会变大   
                               withCompletionHandler:^(NSError *error) {
                                   
                                   if(error)
                                   {
                                       UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.domain delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                       [alertView show];
                                   }
                                   else
                                   {
                                       NSLog(@"保存成功");
                                   
//                                       [[NSFileManager defaultManager] removeItemAtURL:[self returnRecordVideoPath] error:nil];  // 清空路径

                                   }
    }];
}

#pragma mark - 设置录制视频
- (void)setRecordVideo
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"设备无摄象头"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    videoCameraInputManager = [[RTVideoCameraInputManager alloc] init];
    
    videoCameraInputManager.maxDuration = MAX_RECORDING_LENGTH;
    videoCameraInputManager.asyncErrorHandler = ^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.domain delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    };
    
    NSError *error;
    /* 设置录制视频的分辨率 以及前后摄像头灯的开关 */
    [videoCameraInputManager setupSessionWithPreset:CAPTURE_SESSION_PRESET
                                  withCaptureDevice:INITIAL_CAPTURE_DEVICE_POSITION
                                      withTorchMode:INITIAL_TORCH_MODE
                                          withError:&error];
    if(error)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.domain delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:videoCameraInputManager.captureSession];
        
        videoView.videoPreviewView.layer.masksToBounds = YES;
        captureVideoPreviewLayer.frame = videoView.videoPreviewView.bounds;
        
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        [videoView.videoPreviewView.layer insertSublayer:captureVideoPreviewLayer below:videoView.videoPreviewView.layer.sublayers[0]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [videoCameraInputManager.captureSession startRunning];
            
        });
        
        videoView.busyView.frame = CGRectMake(videoView.busyView.frame.origin.x, -videoView.busyView.frame.size.height, videoView.busyView.frame.size.width, videoView.busyView.frame.size.height);
    }
}

#pragma mark - 保存到相册
- (void)saveOutputToAssetLibrary:(NSURL *)outputFileURL completionBlock:(void (^)(NSError *error))completed
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        
        completed(error);
   
    }];
}

#pragma mark - 配置录制视频的路径
- (NSURL *)returnRecordVideoPath
{
    // 录制时 已经指定MP$文件  可直接写.mp4
    NSURL *finalOutputFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.mp4", NSTemporaryDirectory(), VIDEOPATHNAME]];
    return finalOutputFileURL;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 设置只支持home键在下面的方向
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
