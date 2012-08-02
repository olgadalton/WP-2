//
//  SharedMusicPlayer.h
//  ERR
//
//  Created by Olga Dalton on 4/16/12.
//  Copyright (c) 2012 Finestmedia Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WebViewController.h"
#import <CoreMedia/CoreMedia.h>

@class AVPlayer;
@class AVPlayerItem;

@interface SharedMusicPlayer : NSObject
{
    NSURL *movieURL;
    AVPlayer *player;
    AVPlayerItem *playerItem;
    BOOL isSeeking;
    BOOL seekToZeroBeforePlay;
    float restoreAfterScrubbingRate;
    
    id timeObserver;
    NSArray *adList;
    
    BOOL volumeIsOn;
    BOOL toolBarVisible;
    
    WebViewController *currentlyViewed;
    UILabel *timeLabel;
    UIView *timeView;
    
    NSDate *startPlayDate;
    
    BOOL isScrubbingInProcess;
}

@property (retain) AVPlayer *player;
@property (retain) AVPlayerItem *playerItem;
@property BOOL volumeIsOn;
@property BOOL toolBarVisible;
@property (nonatomic, retain) WebViewController *currentlyViewed;
@property (nonatomic, retain) NSDate *startPlayDate;

+ (SharedMusicPlayer *) sharedPlayer;
- (void)loadAudio: (NSString *) audioUrl;
- (void)beginScrubbing;
- (void)endScrubbing;
- (void)togglePlay;
- (void)play;
- (void)stop;
- (void)syncPlayPauseButtons;
- (void)mute;
- (void)unMute;

- (IBAction)scrub:(id)sender;

@end
