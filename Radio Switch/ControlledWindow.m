//
//  ControlledWindow.m
//  ERR
//
//  Created by Olga Dalton on 4/16/12.
//  Copyright (c) 2012 Finestmedia Ltd. All rights reserved.
//

#import "ControlledWindow.h"
#import "SharedMusicPlayer.h"

@implementation ControlledWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"init window with frame");
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(id) init
{
    self = [super init];
    
    //NSLog(@"Custom window init");
    
    return self;
}

-(void)makeKeyAndVisible
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    [super makeKeyAndVisible];
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder 
{
    return YES;
}

-(void) dealloc
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [super dealloc];
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {  
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [[SharedMusicPlayer sharedPlayer] togglePlay];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [[SharedMusicPlayer sharedPlayer] scrub: nil];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [[SharedMusicPlayer sharedPlayer] scrub: nil];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingForward:
                [[SharedMusicPlayer sharedPlayer] endScrubbing];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                [[SharedMusicPlayer sharedPlayer] endScrubbing];
                break;
                
            default:
                break;
        }
    }
}


@end
