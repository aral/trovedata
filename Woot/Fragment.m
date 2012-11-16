//
//  Fragment.m
//  Woot
//
//  Created by Aral Balkan on 16/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "Fragment.h"
#import "GloballyUniqueID.h"

@implementation Fragment

+(id)fragmentWithType:(FragmentType)fragmentType id:(GloballyUniqueID *)fragmentID data:(NSDictionary *)data
{
    return [[self new] initFragmentWithType:fragmentType id:fragmentID data:data];
}

-(id)initFragmentWithType:(FragmentType)fragmentType id:(GloballyUniqueID *)fragmentID data:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        self.fragmentID = fragmentID;
        self.type = fragmentType;
        self.data = data;
    }
    return self;
}

@end
