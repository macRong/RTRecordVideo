//
//  VideoCameraInputManager.m
//  VideoCameraInputManager
//
//  Created by RongTian on 13-10-31.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import "RTVideoCameraInputManager.h"

#import "RTAVAssetStitcher.h"

#import <MobileCoreServices/UTCoreTypes.h>

#define RECORDORIGINALPATH   @"RT_RecordVdieo_Path.mov"

@interface RTVideoCameraInputManager (Private)

- (void)startNotificationObservers;
- (void)endNotificationObservers;

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position;
- (AVCaptureDevice *) audioDevice;

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

- (NSString *)constructCurrentTemporaryFilename;

- (void)cleanTemporaryFiles;

@end

@implementation RTVideoCameraInputManager
{
    bool setupComplete;
    
    AVCaptureDeviceInput *videoInput;
    AVCaptureDeviceInput *audioInput;
    
    AVCaptureMovieFileOutput *movieFileOutput;
    
    AVCaptureVideoOrientation orientation;
    
    id deviceConnectedObserver;
    id deviceDisconnectedObserver;
    id deviceOrientationDidChangeObserver;
    
    NSMutableArray *temporaryFileURLs;
    
    long uniqueTimestamp;
    int currentRecordingSegment;        // 主要是对录制多个视频的处理
    
    CMTime currentFinalDurration;
    int inFlightWrites;
}

#ifdef _FOR_DEBUG_
- (BOOL)respondsToSelector:(SEL)rtSelector
{
    NSString *className = NSStringFromClass([self class]) ;
    NSLog(@"%@ --> RTSelector: %s",className,[NSStringFromSelector(rtSelector)UTF8String]);
    return [super respondsToSelector:rtSelector];
}
#endif

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        setupComplete = NO;
        _isPaused = NO;
        
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        temporaryFileURLs = [[NSMutableArray alloc] init];

        
        currentRecordingSegment = 0;
        inFlightWrites = 0;
        _maxDuration = 0;

        [self startNotificationObservers];
    }
    return self;
}

- (void)dealloc
{
    [_captureSession removeOutput:movieFileOutput];
    
    [self endNotificationObservers];
}

- (void)setupSessionWithPreset:(NSString *)preset withCaptureDevice:(AVCaptureDevicePosition)cd withTorchMode:(AVCaptureTorchMode)tm withError:(NSError **)error
{
    if(setupComplete)
    {
        *error = [NSError errorWithDomain:@"Setup session already complete." code:102 userInfo:nil];
        return;
    }
    
    setupComplete = YES;

	AVCaptureDevice *captureDevice = [self cameraWithPosition:cd];
    
	if ([captureDevice hasTorch])
    {
		if ([captureDevice lockForConfiguration:nil])
        {
			if ([captureDevice isTorchModeSupported:tm])
            {
				[captureDevice setTorchMode:AVCaptureTorchModeOff];   // 打开灯
			}
			[captureDevice unlockForConfiguration];
		}
	}
    
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = preset;
    
    videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:nil];
    if([_captureSession canAddInput:videoInput])
    {
        [_captureSession addInput:videoInput];
    }
    else
    {
        *error = [NSError errorWithDomain:@"Error setting video input." code:101 userInfo:nil];
        return;
    }

    audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    if([_captureSession canAddInput:audioInput])
    {
        [_captureSession addInput:audioInput];
    }
    else
    {
        *error = [NSError errorWithDomain:@"Error setting audio input." code:101 userInfo:nil];
        return;
    }
    
    if([_captureSession canAddOutput:movieFileOutput])
    {
        [_captureSession addOutput:movieFileOutput];
    }
    else
    {
        *error = [NSError errorWithDomain:@"Error setting file output." code:101 userInfo:nil];
        return;
    }
    // ?＝＝＝＝＝＝＝＝＝＝＝＝＝＝ 设置录制视频 ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    AVCaptureVideoDataOutput * videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
	if ([_captureSession canAddOutput:videoOutput])
	{
		[_captureSession addOutput:videoOutput];
	}
	else
	{
		NSLog(@"Couldn't add video output");
	}
    // ?＝＝＝＝＝＝＝＝＝＝＝＝＝＝ end <.待续> ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
}

- (void)startRecording
{
    [temporaryFileURLs removeAllObjects];
    
    currentRecordingSegment = 0;
    _isPaused = NO;
    currentFinalDurration = kCMTimeZero;
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:movieFileOutput.connections];
    if ([videoConnection isVideoOrientationSupported])
    {
        videoConnection.videoOrientation = orientation;
    }
    
    NSURL *outputFileURL = [NSURL fileURLWithPath:[self constructCurrentTemporaryFilename]];
   
    [temporaryFileURLs addObject:outputFileURL];
    
    movieFileOutput.maxRecordedDuration = (_maxDuration > 0) ? CMTimeMakeWithSeconds(_maxDuration, 1500) : kCMTimeInvalid; // ?600

    [movieFileOutput startRecordingToOutputFileURL:outputFileURL recordingDelegate:self];
}

- (void)pauseRecording
{
    _isPaused = YES;
    [movieFileOutput stopRecording];
    
    currentFinalDurration = CMTimeAdd(currentFinalDurration, movieFileOutput.recordedDuration);
}

- (void)resumeRecording
{
    currentRecordingSegment++;
    _isPaused = NO;
    
    NSURL *outputFileURL = [NSURL fileURLWithPath:[self constructCurrentTemporaryFilename]];
    
    [temporaryFileURLs addObject:outputFileURL];
    
    if(_maxDuration > 0)
    {    // ? 600
        movieFileOutput.maxRecordedDuration = CMTimeSubtract(CMTimeMakeWithSeconds(_maxDuration, 1500), currentFinalDurration);
    }
    else
    {
        movieFileOutput.maxRecordedDuration = kCMTimeInvalid;
    }
    
    [movieFileOutput startRecordingToOutputFileURL:outputFileURL recordingDelegate:self];
}

- (void)reset
{
    if (movieFileOutput.isRecording)
    {
        [self pauseRecording];
    }
    
    _isPaused = NO;
}

#pragma mark - 前后摄像头的切换
- (void)changeFrontCamera
{
    NSArray *inputs = self.captureSession.inputs;
    
    for ( AVCaptureDeviceInput *input in inputs ) {
        
        AVCaptureDevice *device = input.device;
        
        if ( [device hasMediaType:AVMediaTypeVideo] ) {

            AVCaptureDevicePosition position = device.position;
            
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            
            if (position == AVCaptureDevicePositionFront)
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            else
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];

            [self.captureSession beginConfiguration];
            
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            
            [self.captureSession commitConfiguration];
            
            break;
            
        }  
    } 
}

- (void)finalizeRecordingToFile:(NSURL *)finalVideoLocationURL withVideoSize:(CGSize)videoSize withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    [self reset];
    NSLog(@"preset ＝ %@   videoSize=%@",preset,NSStringFromCGSize(videoSize));
    NSError *error;
    // 如果本地已经存在 return出去 不在存储处理
    if([finalVideoLocationURL checkResourceIsReachableAndReturnError:&error])
    {
        completionHandler([NSError errorWithDomain:@"输出的路径已存在" code:104 userInfo:nil]);
        return;
    }
    
    if(inFlightWrites != 0)
    {
        completionHandler([NSError errorWithDomain:@"录制视频不完整,请重新录制." code:106 userInfo:nil]);
        return;
    }
    
    RTAVAssetStitcher *stitcher = [[RTAVAssetStitcher alloc] initWithOutputSize:videoSize];
    
    __block NSError *stitcherError;
    
    [temporaryFileURLs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *outputFileURL, NSUInteger idx, BOOL *stop) {
        
        [stitcher addAsset:[AVURLAsset assetWithURL:outputFileURL] withTransform:^CGAffineTransform(AVAssetTrack *videoTrack) {
            
            // videoTrack 480  640
            NSUserDefaults * defaults_Record = [NSUserDefaults standardUserDefaults];
            
            float record_W =  [[defaults_Record objectForKey:@"record_Width"]floatValue];
            float record_H =  [[defaults_Record objectForKey:@"record_Hight"]floatValue];
            
            
            CGFloat ratioW = record_W / videoTrack.naturalSize.width;
            CGFloat ratioH = record_H / videoTrack.naturalSize.height;

            NSLog(@"record video size ratioW = %f  ratioH = %f   videoTrack ＝ %f    %f",ratioW,ratioH,videoTrack.naturalSize.width,videoTrack.naturalSize.height);
            
             // 这里主要判断视频的比率是否大于1   是否要翻转  截取视频的大小
//            if(ratioW < ratioH)
//            {
//
//                float neg = (ratioH > 1.0) ? 1.0 : -1.0;
//                CGFloat diffH = videoTrack.naturalSize.height - (videoTrack.naturalSize.height * ratioH);
//                return CGAffineTransformConcat( CGAffineTransformMakeTranslation(0, neg*diffH/2.0), CGAffineTransformMakeScale(ratioH, ratioH) );
//            }
//            else
//            {
//                float neg = (ratioW > 1.0) ? 1.0 : -1.0;
//                CGFloat diffW = videoTrack.naturalSize.width - (videoTrack.naturalSize.width * ratioW);
//                return CGAffineTransformConcat( CGAffineTransformMakeTranslation(neg*diffW/2.0, 0), CGAffineTransformMakeScale(ratioW, ratioW) );
//            }
            

            return CGAffineTransformConcat( CGAffineTransformMakeTranslation(1,1),CGAffineTransformMakeTranslation(1,1));

       
        } withErrorHandler:^(NSError *error) {
            
            stitcherError = error;
            
        }];
        
    }];
    
    if(stitcherError)
    {
        completionHandler(stitcherError);
        return;
    }
    
    [stitcher exportTo:finalVideoLocationURL withPreset:preset withCompletionHandler:^(NSError *error) {
        
        if(error)
        {
            completionHandler(error);
        }
        else
        {
            [self cleanTemporaryFiles];
            [temporaryFileURLs removeAllObjects];
            
            completionHandler(nil);
        }
    }];
}

- (CMTime)totalRecordingDuration
{
    if(CMTimeCompare(kCMTimeZero, currentFinalDurration) == 0)
    {
        return movieFileOutput.recordedDuration;
    }
    else
    {
        CMTime returnTime = CMTimeAdd(currentFinalDurration, movieFileOutput.recordedDuration);
        return CMTIME_IS_INVALID(returnTime) ? currentFinalDurration : returnTime;
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate implementation

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    inFlightWrites++;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if(error)
    {
        if(self.asyncErrorHandler)
        {
            self.asyncErrorHandler(error);
        }
        else
        {
            NSLog(@"Error capturing output: %@", error);
        }
    }
    
    inFlightWrites--;
}

#pragma mark - Observer start and stop

- (void)startNotificationObservers
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    //
    // Reconnect to a device that was previously being used
    //
    deviceConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        
        AVCaptureDevice *device = [notification object];
        
        NSString *deviceMediaType = nil;
        
        if ([device hasMediaType:AVMediaTypeAudio])
        {
            deviceMediaType = AVMediaTypeAudio;
        }
        else if ([device hasMediaType:AVMediaTypeVideo])
        {
            deviceMediaType = AVMediaTypeVideo;
        }
        
        if (deviceMediaType != nil)
        {
            [_captureSession.inputs enumerateObjectsUsingBlock:^(AVCaptureDeviceInput *input, NSUInteger idx, BOOL *stop) {
            
                if ([input.device hasMediaType:deviceMediaType])
                {
                    NSError	*error;
                    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                    if ([_captureSession canAddInput:deviceInput])
                    {
                        [_captureSession addInput:deviceInput];
                    }
                    
                    if(error)
                    {
                        if(self.asyncErrorHandler)
                        {
                            self.asyncErrorHandler(error);
                        }
                        else
                        {
                            NSLog(@"Error reconnecting device input: %@", error);
                        }
                    }
                    
                    *stop = YES;
                }
            
            }];
        }
        
    }];
    
    deviceDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        
        AVCaptureDevice *device = [notification object];
        
        if ([device hasMediaType:AVMediaTypeAudio])
        {
            [_captureSession removeInput:audioInput];
            audioInput = nil;
        }
        else if ([device hasMediaType:AVMediaTypeVideo])
        {
            [_captureSession removeInput:videoInput];
            videoInput = nil;
        }
        
    }];
    
    /* 跟踪设备的方向  确定视频的正确方向 */
    orientation = AVCaptureVideoOrientationPortrait;
    deviceOrientationDidChangeObserver = [notificationCenter addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        
        switch ([[UIDevice currentDevice] orientation])
        {
            case UIDeviceOrientationPortrait:
                orientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                orientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            case UIDeviceOrientationLandscapeLeft:
                orientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                orientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            default:
                orientation = AVCaptureVideoOrientationPortrait;
                break;
        }
        
    }];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)endNotificationObservers
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:deviceConnectedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:deviceDisconnectedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:deviceOrientationDidChangeObserver];
}

#pragma mark - Device finding methods
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    __block AVCaptureDevice *foundDevice = nil;
    
    [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(AVCaptureDevice *device, NSUInteger idx, BOOL *stop) {
        
        if (device.position == position)
        {
            foundDevice = device;
            *stop = YES;
        }

    }];

    return foundDevice;
}

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if (devices.count > 0)
    {
        return devices[0];
    }
    return nil;
}

#pragma mark - Connection finding method

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    __block AVCaptureConnection *foundConnection = nil;
    
    [connections enumerateObjectsUsingBlock:^(AVCaptureConnection *connection, NSUInteger idx, BOOL *connectionStop) {
        
        [connection.inputPorts enumerateObjectsUsingBlock:^(AVCaptureInputPort *port, NSUInteger idx, BOOL *portStop) {
            
            if( [port.mediaType isEqual:mediaType] )
            {
				foundConnection = connection;
                
                *connectionStop = YES;
                *portStop = YES;
			}
            
        }];
        
    }];
    
	return foundConnection;
}

#pragma  mark - Temporary file handling functions
//- (NSString *)constructCurrentTemporaryFilename
//{
//    return [NSString stringWithFormat:@"%@%@-%ld-%d.mov", NSTemporaryDirectory(), @"recordingsegment", uniqueTimestamp, currentRecordingSegment];
//}
-(NSString *)constructCurrentTemporaryFilename
{
    return [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(),  RECORDORIGINALPATH];
}

- (void)cleanTemporaryFiles
{
    [temporaryFileURLs enumerateObjectsUsingBlock:^(NSURL *temporaryFiles, NSUInteger idx, BOOL *stop) {
        [[NSFileManager defaultManager] removeItemAtURL:temporaryFiles error:nil];
    }];
}

@end
