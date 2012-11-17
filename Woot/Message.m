//
//  Message.m
//  TroveData
//
//  Created by Aral Balkan on 17/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "Message.h"
#import "Operation.h"
#import "Row.h"
#import "Fragment.h"

@implementation Message

+(id)messageWithOperation:(Operation *)operation row:(Row *)row fragment:(Fragment *)fragment
{
    return [[self alloc] initWithOperation:operation row:row fragment:fragment];
}

+(id)messageWithOperation:(Operation *)operation
{
    return [[self alloc] initWithOperation:operation];
}

+(id)messageWithOperation:(Operation *)operation row:(Row *)row
{
    return [[self alloc] initWithOperation:operation row:row];
}

// Designated initialiser.
-(id)initWithOperation:(Operation *)operation row:(Row *)row fragment:(Fragment *)fragment
{
    self = [super init];
    
    if (self)
    {
        self.operation = operation;
        self.row = row;
        self.fragment = fragment;
    }
    
    return self;
}

-(id)initWithOperation:(Operation *)operation
{
    return [self initWithOperation:operation row:nil fragment:nil];
}

-(id)initWithOperation:(Operation *)operation row:(Row *)row
{
    return [self initWithOperation:operation row:row fragment:nil];
}

@end

