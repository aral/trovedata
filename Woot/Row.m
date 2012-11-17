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

@end
