//
//  AVAssetStitcher.m
//  AVAssetStitcher
//
//  Created by RongTian on 13-10-31.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import "RTAVAssetStitcher.h"

@implementation RTAVAssetStitcher
{
    CGSize outputSize;
    
    AVMutableComposition *composition;
    AVMutableCompositionTrack *compositionVideoTrack;
    AVMutableCompositionTrack *compositionAudioTrack;
    
    NSMutableArray *instructions;
}

- (id)initWithOutputSize:(CGSize)outSize
{
    self = [super init];
    if (self != nil)
    {
        
        
        outputSize = outSize;
        composition = [AVMutableComposition composition];
        compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        instructions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addAsset:(AVURLAsset *)asset withTransform:(CGAffineTransform (^)(AVAssetTrack *videoTrack))transformToApply withErrorHandler:(void (^)(NSError *error))errorHandler
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    

    if(transformToApply)
    {
        [layerInstruction setTransform:CGAffineTransformConcat(videoTrack.preferredTransform, transformToApply(videoTrack))
                                atTime:kCMTimeZero];
    }
    else
    {
        [layerInstruction setTransform:videoTrack.preferredTransform
                                atTime:kCMTimeZero];
    }


    instruction.layerInstructions = @[layerInstruction];
    
    __block CMTime startTime = kCMTimeZero;
    [instructions enumerateObjectsUsingBlock:^(AVMutableVideoCompositionInstruction *previousInstruction, NSUInteger idx, BOOL *stop) {
        startTime = CMTimeAdd(startTime, previousInstruction.timeRange.duration);
    }];
    instruction.timeRange = CMTimeRangeMake(startTime, asset.duration);
    
    [instructions addObject:instruction];
    
    NSError *error;
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    
    if(error)
    {
        errorHandler(error);
        return;
    }
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    if(error)
    {
        errorHandler(error);
        return;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [instructions removeAllObjects];
}

- (void)exportTo:(NSURL *)outputFile withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = instructions;
    
    NSUserDefaults * defaults_Record = [NSUserDefaults standardUserDefaults];
    
    float record_W =  [[defaults_Record objectForKey:@"record_Width"]floatValue];
    float record_H =  [[defaults_Record objectForKey:@"record_Hight"]floatValue];
    
    CGSize videoRenderSize  = CGSizeMake(record_W, record_H);
    videoComposition.renderSize = videoRenderSize;   // ?
    NSLog(@"record video size ratioW = %f  ratioH = %f",record_W,record_H);
    
    videoComposition.frameDuration = CMTimeMake(1, 30);   // ?   30
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:preset];
    NSParameterAssert(exporter != nil);
    
    
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = outputFile;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch([exporter status])
        {
            case AVAssetExportSessionStatusFailed:
            {
                completionHandler(exporter.error);
            } break;
            case AVAssetExportSessionStatusCancelled:
            case AVAssetExportSessionStatusCompleted:
            {
                completionHandler(nil);
            } break;
            default:
            {
                completionHandler([NSError errorWithDomain:@"Unknown export error" code:100 userInfo:nil]);
            } break;
        }
        
    }];
}

@end

