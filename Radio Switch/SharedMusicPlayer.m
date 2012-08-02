//
//  SharedMusicPlayer.m
//  ERR
//
//  Created by Olga Dalton on 4/16/12.
//  Copyright (c) 2012 Finestmedia Ltd. All rights reserved.
//

#import "SharedMusicPlayer.h"
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

#define APPDELEGATE ((AppDelegate *)[[UIApplication sharedApplication] delegate])

static void *MyStreamingMovieViewControllerTimedMetadataObserverContext = &MyStreamingMovieViewControllerTimedMetadataObserverContext;
static void *MyStreamingMovieViewControllerRateObservationContext = &MyStreamingMovieViewControllerRateObservationContext;
static void *MyStreamingMovieViewControllerCurrentItemObservationContext = &MyStreamingMovieViewControllerCurrentItemObservationContext;
static void *MyStreamingMovieViewControllerPlayerItemStatusObserverContext = &MyStreamingMovieViewControllerPlayerItemStatusObserverContext;

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"timedMetadata";

#pragma mark -
@interface SharedMusicPlayer (Player)
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata;
- (void)updateAdList:(NSArray *)newAdList;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end


@implementation SharedMusicPlayer

@synthesize player, playerItem, volumeIsOn, toolBarVisible, currentlyViewed;
@synthesize startPlayDate;

static SharedMusicPlayer *sharedMusicPlayer = nil;

+(SharedMusicPlayer *) sharedPlayer 
{
    @synchronized([SharedMusicPlayer class])
    {
        if (!sharedMusicPlayer)
        {
            [[self alloc] init];
        }
        return sharedMusicPlayer;
    }
    return nil;
}

+(id) alloc
{
    @synchronized([SharedMusicPlayer class])
    {
        if (sharedMusicPlayer == nil)
        {
            sharedMusicPlayer = [super alloc];
        }
        return sharedMusicPlayer;
    }
    return nil;
}

-(id) init
{
    self = [super init];
    
    if (self)
    {
        self.volumeIsOn = YES;
        
        UIBarButtonItem *scrubberItem = [[UIBarButtonItem alloc] initWithCustomView:APPDELEGATE.movieTimeControl];
        
        [APPDELEGATE.toolBar setHidden: NO];
        
        APPDELEGATE.movieTimeControl.hidden = NO;
        
        UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        timeView = [[[UIView alloc] initWithFrame: CGRectMake(0.0, 0.0, 75.0, 20.0)] autorelease];
        timeLabel = [[[UILabel alloc] initWithFrame: timeView.frame] autorelease];
        [timeLabel setTextAlignment: UITextAlignmentCenter];
        [timeLabel setFont: [UIFont boldSystemFontOfSize: 13.0f]];
        [timeLabel setTextColor: [UIColor whiteColor]];
        [timeLabel setBackgroundColor: [UIColor clearColor]];
        [timeView addSubview: timeLabel];
        [timeLabel setText: @"0:00/0:00"];
        
        UIBarButtonItem *timeItem = [[[UIBarButtonItem alloc] initWithCustomView: timeView] autorelease];
        
        UIBarButtonItem *fixedItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL] autorelease];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            APPDELEGATE.toolBar.items = [NSArray arrayWithObjects: fixedItem, flexItem, APPDELEGATE.playButton, scrubberItem, timeItem, APPDELEGATE.hideButton, flexItem, fixedItem, nil];
        }
        else
        {
            APPDELEGATE.toolBar.items = [NSArray arrayWithObjects: APPDELEGATE.playButton, flexItem, scrubberItem, flexItem, timeItem, APPDELEGATE.hideButton, nil];
        }
        
        [scrubberItem release];
        [flexItem release];

        [self play];
        [self stop];
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        toolBarVisible = NO;
    }
    return self;
}

-(void) dealloc
{
    [timeObserver release];
    [movieURL release];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    [self.player removeObserver:self forKeyPath:kCurrentItemKey];
    [self.player removeObserver:self forKeyPath:kTimedMetadataKey];
    [self.player removeObserver:self forKeyPath:kRateKey];
    
    [player release];
    [playerItem release];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [super dealloc];
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {  
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                
                [self syncPlayPauseButtons];
                
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [self scrub: nil];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [self scrub: nil];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingForward:
                [self endScrubbing];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                [self endScrubbing];
                break;
                
            default:
                break;
        }
    }
}

-(void)mute
{
    AVURLAsset *asset = (AVURLAsset*)[[self.player currentItem] asset];
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    // Mute all the audio tracks
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =    [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:0.0 atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [[self.player currentItem] setAudioMix:audioZeroMix];
}

-(void)unMute
{
    [player play];
    //[self loadAudio: [movieURL absoluteString]];
}


#pragma Player methods

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    int index = 0;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        index = 2;
    }
    
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[APPDELEGATE.toolBar items]];
    [toolbarItems replaceObjectAtIndex:index withObject:APPDELEGATE.stopButton];
    APPDELEGATE.toolBar.items = toolbarItems;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    int index = 0;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        index = 2;
    }
    
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[APPDELEGATE.toolBar items]];
    [toolbarItems replaceObjectAtIndex:index withObject:APPDELEGATE.playButton];
    APPDELEGATE.toolBar.items = toolbarItems;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        [self showStopButton];
	}
	else
	{
        [self showPlayButton];        
	}
}

-(void)enablePlayerButtons
{
    APPDELEGATE.playButton.enabled = YES;
    APPDELEGATE.stopButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    APPDELEGATE.playButton.enabled = NO;
    APPDELEGATE.stopButton.enabled = NO;
}

#pragma mark Scrubber control

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    if (isScrubbingInProcess)
    {
        return;
    }
    
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		APPDELEGATE.movieTimeControl.minimumValue = 0.0;
		return;
	} 
	
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration) && (duration > 0))
	{
		float minValue = [APPDELEGATE.movieTimeControl minimumValue];
		float maxValue = [APPDELEGATE.movieTimeControl maximumValue];
		double time = CMTimeGetSeconds([player currentTime]);
		[APPDELEGATE.movieTimeControl setValue:(maxValue - minValue) * time / duration + minValue];
        
        if (timeLabel)
        {
            //[timeView setFrame: CGRectMake(0.0, 0.0, 70.0, 20.0)];
            [timeLabel setText: [NSString stringWithFormat:@"%d:%02d/%d:%02d", (int)(time/60), ((int)time)%60, (int)(duration/60), ((int)duration%60)]];
        }
        
        APPDELEGATE.movieTimeControl.enabled = YES;
	}
    else 
    {
        if (timeLabel)
        {
            double interval = [[NSDate date] timeIntervalSinceDate: self.startPlayDate];
            [timeLabel setText: [NSString stringWithFormat: @"%d:%02d/0:00", (int)(interval/60), ((int)interval)%60]];
        }
        
        APPDELEGATE.movieTimeControl.enabled = NO;
    }
}

/* Requests invocation of a given block during media playback to update the 
 movie scrubber control. */
-(void)initScrubberTimer
{
	double interval = 0.1;	
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		return;
	} 
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		//CGFloat width = CGRectGetWidth([APPDELEGATE.movieTimeControl bounds]);
		//interval = 0.5f * duration / width;
	}
    
	/* Update the scrubber during normal playback. */
	timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                         queue:NULL 
                                                    usingBlock:
                     ^(CMTime time) 
                     {
                         [self syncScrubber];
                     }] retain];
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if (timeObserver)
	{
		[player removeTimeObserver:timeObserver];
		[timeObserver release];
		timeObserver = nil;
	}
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)beginScrubbing
{
    NSLog(@"Begin scrubbing");
    isScrubbingInProcess = YES;
	restoreAfterScrubbingRate = [player rate];
	[player setRate:0.f];
	
	/* Remove previous timer. */
	[self removePlayerTimeObserver];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing
{
@try 
    {
    isScrubbingInProcess = NO;
    
	if (!timeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) 
		{
			return;
		} 
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([APPDELEGATE.movieTimeControl bounds]);
			double tolerance = 0.5f * duration / width;
            
			timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
                             ^(CMTime time)
                             {
                                 [self syncScrubber];
                             }] retain];
		}
        else 
        {
            double interval = .1f;
            /* Update the scrubber during normal playback. */
            timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                                 queue:NULL 
                                                            usingBlock:
                             ^(CMTime time) 
                             {
                                 [self syncScrubber];
                             }] retain];
        }
	}
    
	if (restoreAfterScrubbingRate)
	{
		[player setRate:restoreAfterScrubbingRate];
		restoreAfterScrubbingRate = 0.f;
	}
    }
    @catch (NSException *exception) {}
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
    isScrubbingInProcess = YES;
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		} 
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
			[player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
}

- (BOOL)isScrubbing
{
	return restoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    APPDELEGATE.movieTimeControl.enabled = YES;
}

-(void)disableScrubber
{
    APPDELEGATE.movieTimeControl.enabled = NO;    
}

/* Prevent the slider from seeking during Ad playback. */
- (void)sliderSyncToPlayerSeekableTimeRanges
{		
	NSArray *seekableTimeRanges = [[player currentItem] seekableTimeRanges];
	if ([seekableTimeRanges count] > 0) 
	{
		NSValue *range = [seekableTimeRanges objectAtIndex:0];
		CMTimeRange timeRange = [range CMTimeRangeValue];
		float startSeconds = CMTimeGetSeconds(timeRange.start);
		float durationSeconds = CMTimeGetSeconds(timeRange.duration);
		
		/* Set the minimum and maximum values of the time slider to match the seekable time range. */
		APPDELEGATE.movieTimeControl.minimumValue = startSeconds;
		APPDELEGATE.movieTimeControl.maximumValue = startSeconds + durationSeconds;
	}
}

#pragma mark Button Action Methods

- (void)play
{
	/* If we are at the end of the movie, we must seek to the beginning first 
     before starting playback. */
	if (YES == seekToZeroBeforePlay) 
	{
		seekToZeroBeforePlay = NO;
		[player seekToTime:kCMTimeZero];
	}
    
	[player play];
	
    [self showStopButton];  
}

- (void)stop
{
    @try 
    {
        [player pause];
        
        [self showPlayButton];
    }
    @catch (NSException *exception) {}
}

-(void)loadAudio: (NSString *) audioUrl
{
	/* Has the user entered a movie URL? */
	if (audioUrl.length > 0)
	{
		NSURL *newMovieURL = [NSURL URLWithString:audioUrl];
        
        self.startPlayDate = [NSDate date];
        
        if (timeLabel)
        {
            [timeLabel setText: @"0:00/0:00"];
        }
        
		if ([newMovieURL scheme])	/* Sanity check on the URL. */
		{
			/*
			 Create an asset for inspection of a resource referenced by a given URL.
			 Load the values for the asset keys "tracks", "playable".
			 */
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:newMovieURL options:nil];
            
			NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
			
			/* Tells the asset to load the values of any of the specified keys that are not already loaded. */
			[asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
			 ^{		 
				 dispatch_async( dispatch_get_main_queue(), 
								^{
									/* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
									[self prepareToPlayAsset:asset withKeys:requestedKeys];
								});
			 }];
		}
	}
}

-(void)togglePlay
{
    if ([self isPlaying])
    {
        [self stop];
    }
    else 
    {
        [self play];
    }
    
    [self syncPlayPauseButtons];
}

@end


@implementation SharedMusicPlayer (Player)

#pragma mark -

#pragma mark Player

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem. 
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
	AVPlayerItem *thePlayerItem = [player currentItem];
	if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
	{        
        /* 
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice 
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3. 
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching 
         the value of the duration property of its associated AVAsset object. However, 
         note that for HTTP Live Streaming Media the duration of a player item during 
         any particular playback session may differ from the duration of its asset. For 
         this reason a new key-value observable duration property has been defined on 
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */		
        
       // CMTime time = [playerItem duration];
        
        //NSLog(@"Item duration - %4.2lld", (time.value/time.timescale));
        
		return([playerItem duration]);
	}
    
	return(kCMTimeInvalid);
}

- (BOOL)isPlaying
{
	return restoreAfterScrubbingRate != 0.f || [player rate] != 0.f;
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification 
{
	/* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self showPlayButton];
    
	/* After the movie has played to its end time, seek back to time zero 
     to play it again */
	seekToZeroBeforePlay = YES;
}

-(void)metadataChanged: (NSNotification *) notification
{
    NSLog(@"Metadata changed - %@", notification);
}

#pragma mark -
#pragma mark Timed metadata
#pragma mark -

- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata
{
	/* We expect the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries. */
	if ([(NSString *)[timedMetadata key] isEqualToString:AVMetadataID3MetadataKeyGeneralEncapsulatedObject]) 
	{
		if ([[timedMetadata value] isKindOfClass:[NSDictionary class]]) 
		{
			NSDictionary *propertyList = (NSDictionary *)[timedMetadata value];
            
			/* Metadata payload could be the list of ads. */
			NSArray *newAdList = [propertyList objectForKey:@"ad-list"];
			if (newAdList != nil) 
			{
				[self updateAdList:newAdList];
				NSLog(@"ad-list is %@", newAdList);
			}
            
			/* Or it might be an ad record. */
			NSString *adURL = [propertyList objectForKey:@"url"];
			if (adURL != nil) 
			{
				if ([adURL isEqualToString:@""]) 
				{
					/* Ad is not playing, so clear text. */
					//self.isPlayingAdText.text = @"";
                    
                    [self enablePlayerButtons];
                    [self enableScrubber]; /* Enable seeking for main content. */
                    
					NSLog(@"enabling seek at %g", CMTimeGetSeconds([player currentTime]));
				}
				else 
				{
					/* Display text indicating that an Ad is now playing. */
					//self.isPlayingAdText.text = @"< Ad now playing, seeking is disabled on the movie controller... >";
					
                    [self disablePlayerButtons];
                    [self disableScrubber]; 	/* Disable seeking for ad content. */
                    
					NSLog(@"disabling seek at %g", CMTimeGetSeconds([player currentTime]));
				}
			}
		}
	}
}

#pragma mark Ad list

/* Update current ad list, set slider to match current player item seekable time ranges */
- (void)updateAdList:(NSArray *)newAdList
{
	if (!adList || ![adList isEqualToArray:newAdList]) 
	{
		newAdList = [newAdList copy];
		[adList release];
		adList = newAdList;
        
		[self sliderSyncToPlayerSeekableTimeRanges];
	}
}	

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 ** 
 **  1) values of asset keys did not load successfully, 
 **  2) the asset keys did load successfully, but the asset is not 
 **     playable
 **  3) the item did not become ready to play. 
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

#pragma mark Prepare to play asset

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
	/*for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		// If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail 
        //out properly in the case of cancellation. 
	}*/
    
    @try {
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) 
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */
    
	[self initScrubberTimer];
	[self enableScrubber];
	[self enablePlayerButtons];
	
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];            
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self 
                      forKeyPath:kStatusKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MyStreamingMovieViewControllerPlayerItemStatusObserverContext];
        
    
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
	
    seekToZeroBeforePlay = NO;
	
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];	
		
        /* Observe the AVPlayer "currentItem" property to find out when any 
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
         occur.*/
        [self.player addObserver:self 
                      forKeyPath:kCurrentItemKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MyStreamingMovieViewControllerCurrentItemObservationContext];
        
        /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */			
        [self.player addObserver:self 
                      forKeyPath:kTimedMetadataKey 
                         options:0 
                         context:MyStreamingMovieViewControllerTimedMetadataObserverContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self 
                      forKeyPath:kRateKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MyStreamingMovieViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs 
         asynchronously; observe the currentItem property to find out when the 
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
    
    [self play];
	
    [APPDELEGATE.movieTimeControl setValue:0.0];
        
    }
    @catch (NSException *exception){}
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed. 
 **  Adjust the movie play and pause button controls when the 
 **  player item "status" value changes. Update the movie 
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item 
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the 
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path 
                      ofObject:(id)object 
                        change:(NSDictionary*)change 
                       context:(void*)context
{
    
    NSLog(@"path - %@", path);
    
	/* AVPlayerItem "status" property value observer. */
	if (context == MyStreamingMovieViewControllerPlayerItemStatusObserverContext)
	{
		[self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because 
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e. 
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [APPDELEGATE.toolBar setHidden:NO];
                
                /* Show the movie slider control since the movie is now ready to play. */
                APPDELEGATE.movieTimeControl.hidden = NO;
                
                [self enableScrubber];
                [self enablePlayerButtons];
                
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */	
                
                [self initScrubberTimer];
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == MyStreamingMovieViewControllerRateObservationContext)
	{
        [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer. 
     Called when the AVPlayer replaceCurrentItemWithPlayerItem: 
     replacement will/did occur. */
	else if (context == MyStreamingMovieViewControllerCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* New player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
            
            //self.isPlayingAdText.text = @"";
        }
        else /* Replacement of player currentItem has occurred */
        {
            [self syncPlayPauseButtons];
        }
	}
	/* Observe the AVPlayer "currentItem.timedMetadata" property to parse the media stream 
     timed metadata. */
	else if (context == MyStreamingMovieViewControllerTimedMetadataObserverContext) 
	{
		NSArray* array = [[player currentItem] timedMetadata];
		for (AVMetadataItem *metadataItem in array) 
		{
			[self handleTimedMetadata:metadataItem];
		}
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
    
    return;
}

@end

