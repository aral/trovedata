//
//  WootAtom.m
//  Woot
//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "Row.h"
#import "GloballyUniqueID.h"

@implementation Row

#pragma mark - Globally *constant* special rows with constant global IDs.

//
// Every post has a first row and a last row that are constant markers. They
// do not vary from post to post or user to user or device to device. We use
// special globally constant IDs for these.
//

+(id)firstRow
{
    // Note: Even if this class is subclassed, typing this object
    // to Row * will still hold as all subclasses are still Row instances.
    static Row *firstRow = nil;
    
    if (firstRow == nil) {
        firstRow = [self new];
        firstRow.rowID = [GloballyUniqueID idWithGloballyUniqueIDString:@"0-0"];
    }
    
    return firstRow;
}

+(id)lastRow
{
    static Row *lastRow = nil;
    if (lastRow == nil) {
        lastRow = [self new];
        lastRow.rowID = [GloballyUniqueID idWithGloballyUniqueIDString:@"0-1"];
    }
    
    return lastRow;
}


@end
