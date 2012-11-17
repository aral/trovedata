//
//  BaseRow.m
//  
//
//  Created by Aral Balkan on 17/11/2012.
//
//

#import "BaseRow.h"
#import "GloballyUniqueID.h"

@implementation BaseRow

//
// Every post has a first row and a last row that are constant markers. They
// do not vary from post to post or user to user or device to device. We use
// special globally constant IDs for these.
//

+(id)first
{
    // Note: Even if this class is subclassed, typing this object
    // to Row * will still hold as all subclasses are still Row instances.
    static BaseRow *firstRow = nil;
    
    if (firstRow == nil) {
        firstRow = [self new];
        firstRow.rowID = [GloballyUniqueID idWithGloballyUniqueIDString:@"0-0"];
    }
    
    return firstRow;
}

+(id)last
{
    static BaseRow *lastRow = nil;
    if (lastRow == nil) {
        lastRow = [self new];
        lastRow.rowID = [GloballyUniqueID idWithGloballyUniqueIDString:@"0-1"];
    }
    
    return lastRow;
}

@end
