//
//  PitchDetector.m
//  Radio Switch
//
//  Created by Olga Dalton on 7/30/12.
//  Copyright (c) 2012 Olga Dalton. All rights reserved.
//

#import "PitchDetector.h"

@implementation PitchDetector

static PitchDetector *sharedDetector = nil;

+(PitchDetector *) sharedDetector
{
    @synchronized([PitchDetector class])
    {
        if (!sharedDetector) 
        {
            [[self alloc] init];
        }
        return sharedDetector;
    }
    return nil;
}


+(id) alloc
{
    @synchronized([PitchDetector class])
    {
        if (sharedDetector == nil) 
        {
            sharedDetector = [super alloc];
        }
        return sharedDetector;
    }
    return nil;
}

-(id) init
{
    self = [super init];
    
    if (self) 
    {
        //
    }
    
    return self;
}

@end
