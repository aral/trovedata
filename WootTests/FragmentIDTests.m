//
//  WootIDTests.m
//  Woot
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "FragmentIDTests.h"
#import "FragmentID.h"

@implementation FragmentIDTests

-(void)testUniqueness
{
    FragmentID *id1 = [FragmentID nextID];
    FragmentID *id2 = [FragmentID nextID];
    
    STAssertFalse([id1.stringValue isEqualToString:id2.stringValue], @"IDs should be unique");
    STAssertTrue(id2.localClock > id1.localClock, @"IDs should be in accending order");
}

@end
