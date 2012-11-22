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

+(id)rowWithContent:(id)content rowID:(GloballyUniqueID *)rowID previousRowID:(GloballyUniqueID *)previousRowID nextRowID:(GloballyUniqueID *)nextRowID
{
    return [[self alloc] initWithContent:content rowID:rowID previousRowID:previousRowID nextRowID:nextRowID];
}

-(id)initWithContent:(id)content rowID:(GloballyUniqueID *)rowID previousRowID:(GloballyUniqueID *)previousRowID nextRowID:(GloballyUniqueID *)nextRowID
{
    self = [super init];
    if (self)
    {
        self.content = content;
        self.selfID = rowID;
        self.previousID = previousRowID;
        self.nextID = nextRowID;
        self.visibilityDegree = 1;
    }
    return self;
}

-(NSString *)description
{
    NSString *desc = nil;
    if ([self.selfID.stringValue isEqualToString:@"0-0"])
    {
        desc = @"First row";
    }
    else if ([self.selfID.stringValue isEqualToString:@"0-1"])
    {
        desc = @"Last row";
    }
    else
    {
        desc = [NSString stringWithFormat:@"Row with id: %@ prevID: %@ nextID: %@ visibilityDegree: %lu content: %@", self.selfID, self.previousID, self.nextID, self.visibilityDegree, self.content];
    }
    return desc;
}

@end
