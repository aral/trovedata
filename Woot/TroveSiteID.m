//
//  TroveSiteID.m
//  Singleton — the site ID.
//
//  The Site ID is currently the MAC address.
//
//  TODO (?): The SiteID is unique for each run of the app and uses a combination of
//  the userID (email address), MAC address, and timestamp at start of the app.
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "TroveSiteID.h"

#import "GetPrimaryMACAddress.c"
#import <IOKit/IOKitLib.h>
#import <IOKit/network/IOEthernetInterface.h>
#import <IOKit/network/IONetworkInterface.h>
#import <IOKit/network/IOEthernetController.h>

@implementation TroveSiteID

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.MACAddress = [self MACAddress];
    }
    return self;
}

- (NSString *)stringValue
{
    NSString *str = [NSString stringWithFormat:@"%@", self.MACAddress];
    return str;
}

#pragma mark - MAC address

-(NSString *)MACAddress
{
    kern_return_t	kernResult = KERN_SUCCESS;
    io_iterator_t	intfIterator;
    UInt8			MACAddress[kIOEthernetAddressSize];
    
    kernResult = FindEthernetInterfaces(&intfIterator);
    
    if (KERN_SUCCESS != kernResult) {
        printf("FindEthernetInterfaces returned 0x%08x\n", kernResult);
    }
    else {
        kernResult = GetMACAddress(intfIterator, MACAddress, sizeof(MACAddress));
        
        if (KERN_SUCCESS != kernResult) {
            printf("Error: GetMACAddress returned 0x%08x\n", kernResult);
            return @"ERROR";
        }
		else {
			printf("This system's built-in MAC address is %02x:%02x:%02x:%02x:%02x:%02x.\n",
                   MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]);
		}
    }
    
    (void) IOObjectRelease(intfIterator);	// Release the iterator.
    
    NSString *MACAddressAsString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]];

    return MACAddressAsString;
}


@end
