//
//  AVAssetStitcher.h
//  AVAssetStitcher
//
//  Created by RongTian on 13-10-31.
//  Copyright (c) 2013年 RongTian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface RTAVAssetStitcher : NSObject

- (id)initWithOutputSize:(CGSize)outSize;

- (void)addAsset:(AVURLAsset *)asset withTransform:(CGAffineTransform (^)(AVAssetTrack *videoTrack))transformToApply withErrorHandler:(void (^)(NSError *error))errorHandler;

- (void)exportTo:(NSURL *)outputFile withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completed;



@end