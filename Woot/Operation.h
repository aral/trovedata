//
//  Operation.h
//  TroveData
//
//  Created by Aral Balkan on 17/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRow.h"

@class GloballyUniqueID;

typedef enum {
    OperationTypeInsert = 1,
    OperationTypeDelete = 2,
    OperationTypeMove = 3,
    OperationTypeUndo = 4,
    OperationTypeRedo = 5
} OperationType;

@interface Operation : BaseRow
@property (nonatomic, assign) OperationType type;
@property (nonatomic, strong) GloballyUniqueID *selfID;
@property (nonatomic, strong) GloballyUniqueID *targetOpID;
@property (nonatomic, strong) GloballyUniqueID *rowID;
@property (nonatomic, strong) GloballyUniqueID *targetRowID;

+(id)insertOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID;
+(id)deleteOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID;
+(id)moveOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID targetRowID:(GloballyUniqueID *)targetRowID;
+(id)undoOperationWithID:(GloballyUniqueID *)opID targetOperationID:(GloballyUniqueID *)targetOpID;
+(id)redoOperationWithID:(GloballyUniqueID *)opID targetOperationID:(GloballyUniqueID *)targetOpID;

// Designated initialiser
-(id)initWithID:(GloballyUniqueID *)opID type:(OperationType)type rowID:(GloballyUniqueID *)rowID targetOperationID:(GloballyUniqueID *)targetOpID targetRowID:(GloballyUniqueID *)targetRowID;

-(id)initInsertOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID;
-(id)initDeleteOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID;
-(id)initMoveOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID targetRowID:(GloballyUniqueID *)targetRowID;
-(id)initUndoOperationWithID:opID targetOperationID:(GloballyUniqueID *)targetOpID;
-(id)initRedoOperationWithID:opID targetOperationID:(GloballyUniqueID *)targetOpID;

@end
