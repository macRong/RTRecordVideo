//
//  VideoCameraInputManager.h
//  VideoCameraInputManager
//
//  Created by RongTian on 13-10-31.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^ErrorHandlingBlock)(NSError *error);

@interface RTVideoCameraInputManager : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (strong, readonly) AVCaptureSession *captureSession;
@property (assign, readonly) bool isPaused;
@property (assign, readwrite) float maxDuration;
@property (copy, readwrite) ErrorHandlingBlock asyncErrorHandler;

- (void)setupSessionWithPreset:(NSString *)preset withCaptureDevice:(AVCaptureDevicePosition)cd withTorchMode:(AVCaptureTorchMode)tm withError:(NSError **)error;

- (void)startRecording;
- (void)pauseRecording;
- (void)resumeRecording;

- (void)reset;

- (void)finalizeRecordingToFile:(NSURL *)finalVideoLocationURL withVideoSize:(CGSize)videoSize withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler;

- (CMTime)totalRecordingDuration;

// 前后摄像头的切换
- (void)changeFrontCamera;

@end
