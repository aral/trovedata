//
//  WootIDTests.m
//  Woot
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "WootIDTests.h"
#import "WootID.h"

@implementation WootIDTests

-(void)testUniqueness
{
    WootID *id1 = [WootID nextID];
    WootID *id2 = [WootID nextID];
    
    STAssertFalse([id1.stringValue isEqualToString:id2.stringValue], @"IDs should be unique");
    STAssertTrue(id2.localClock > id1.localClock, @"IDs should be in accending order");
}

@end
