//
//  WootID.m
//  Woot
//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "GloballyUniqueID.h"

@implementation GloballyUniqueID

#pragma mark - Class methods

+(id)idWithSiteIDString:(NSString *)siteID localClock:(NSUInteger)localClock
{
    return [[self alloc] initWithSiteIDString:siteID localClock:localClock];
}

+(id)idWithGloballyUniqueIDString:(NSString *)globallyUniqueIDString
{
    return [[self alloc] initWithGloballyUniqueIDString:globallyUniqueIDString];
}

#pragma mark - Instance methods

-(id)initWithSiteIDString:(NSString *)siteID localClock:(NSUInteger)localClock
{
    self = [super init];
    if (self)
    {
        self.siteID = siteID;
        self.localClock = localClock;
    }
    return self;
}

-(id)initWithGloballyUniqueIDString:(NSString *)globallyUniqueIDString
{
    self = [super init];
    if (self)
    {
        NSArray *idComponents = [globallyUniqueIDString componentsSeparatedByString:@"-"];
        if (idComponents.count != 2)
        {
            NSLog(@"Error: Globally unique IDs should be in the form SITEID-LOCALCLOCK. Got: %@ instead.", globallyUniqueIDString);
        }
        else
        {
            self.siteID = idComponents[0];
            
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            NSNumber *localClock = [numberFormatter numberFromString:idComponents[1]];
            
            self.localClock = [localClock unsignedIntegerValue];
        }
    }
    return self;
}

-(NSString *)stringValue
{
    NSString *str = [NSString stringWithFormat: @"%@-%lu", self.siteID, self.localClock];
    return str;
}

-(NSString *)description
{
    return [self stringValue];
}

@end
