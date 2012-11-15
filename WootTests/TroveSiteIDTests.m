//
//  TroveSiteIDTests.m
//  Woot
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "TroveSiteIDTests.h"
#import "TroveSiteID.h"

@implementation TroveSiteIDTests

- (void)testMACAddress
{
    TroveSiteID *troveSiteId = [TroveSiteID sharedInstance];
    NSString *macAddress = [troveSiteId MACAddress];
    
    STAssertTrue(macAddress.length == 12, @"MAC address length should be 12 characters.");
    STAssertFalse([macAddress isEqualToString: @"ERROR"], @"MAC address should not return error.");
    STAssertFalse([macAddress isEqualToString: @""], @"MAC address should not be an empty string.");
}

@end
