//
//  Operation.m
//  TroveData
//
//  Created by Aral Balkan on 17/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "Operation.h"
#import "GloballyUniqueID.h"

@implementation Operation

+(id)insertOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID
{
    return [[self alloc] initInsertOperationWithID:opID rowID:rowID];
}

+(id)deleteOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID
{
    return [[self alloc] initDeleteOperationWithID:opID rowID:rowID];
}

+(id)moveOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID targetRowID:(GloballyUniqueID *)targetRowID
{
    return [[self alloc] initMoveOperationWithID:opID rowID:rowID targetRowID:targetRowID];
}

+(id)undoOperationWithID:(GloballyUniqueID *)opID targetOperationID:(GloballyUniqueID *)targetOpID
{
    return [[self alloc] initUndoOperationWithID:opID targetOperationID:targetOpID];
}

+(id)redoOperationWithID:(GloballyUniqueID *)opID targetOperationID:(GloballyUniqueID *)targetOpID
{
    return [[self alloc] initRedoOperationWithID:(GloballyUniqueID *)opID targetOperationID:targetOpID];
}


-(id)initWithID:(GloballyUniqueID *)opID type:(OperationType)type rowID:(GloballyUniqueID *)rowID targetOperationID:(GloballyUniqueID *)targetOpID targetRowID:(GloballyUniqueID *)targetRowID
{
    self = [super init];
    
    if (self)
    {
        self.selfID = opID;
        self.type = type;
        self.rowID = rowID;
        self.targetRowID = targetRowID;
    }
    
    return self;
}

-(id)initInsertOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID
{
    return [self initWithID:opID type:OperationTypeInsert rowID:rowID targetOperationID:nil targetRowID:nil];
}

-(id)initDeleteOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID
{
    return [self initWithID:opID type:OperationTypeDelete rowID:rowID targetOperationID:nil targetRowID:nil];
}

-(id)initMoveOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID targetRowID:(GloballyUniqueID *)targetRowID
{
    return [self initWithID:opID type:OperationTypeMove rowID:rowID targetOperationID:nil targetRowID:targetRowID];
}

-(id)initUndoOperationWithID:opID targetOperationID:(GloballyUniqueID *)targetOpID
{
    return [self initWithID:opID type:OperationTypeUndo rowID:nil targetOperationID:targetOpID targetRowID:nil];
}

-(id)initRedoOperationWithID:opID targetOperationID:(GloballyUniqueID *)targetOpID
{
    return [self initWithID:opID type:OperationTypeRedo rowID:nil targetOperationID:targetOpID targetRowID:nil];
}


@end
