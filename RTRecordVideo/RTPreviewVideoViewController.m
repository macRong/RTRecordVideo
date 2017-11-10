//
//  RTPreviewVideoViewController.m
//  RTRecordVideo
//
//  Created by RongTian on 13-11-11.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import "RTPreviewVideoViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
@interface RTPreviewVideoViewController ()

- (void)addAvplayer:(NSURL *)prevideoPath;
@end

@implementation RTPreviewVideoViewController
@synthesize previewVideoPath = _previewVideoPath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)addAvplayer:(NSURL *)prevideoPath
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"RTVIDEOCORD" ofType:@"mp4"];
    NSURL *sourceMovieURL = [NSURL fileURLWithPath:filePath];
    
    AVAsset *movieAsset	= [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.view.layer addSublayer:playerLayer];
    [player play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
