//
//  Operation.h
//  TroveData
//
//  Created by Aral Balkan on 17/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GloballyUniqueID;

typedef enum {
    OperationTypeInsert = 1,
    OperationTypeDelete = 2,
    OperationTypeMove = 3,
    OperationTypeUndo = 4,
    OperationTypeRedo = 5
} OperationType;

@interface Operation : NSObject
@property (nonatomic, strong) GloballyUniqueID *opID;
@property (nonatomic, assign) OperationType type;
@property (nonatomic, strong) GloballyUniqueID *rowID;
@property (nonatomic, strong) GloballyUniqueID *targetOpID;
@property (nonatomic, strong) GloballyUniqueID *targetRowID;

+(id)insertOperationWithRowID:(GloballyUniqueID *)rowID;
+(id)deleteOperationWithRowID:(GloballyUniqueID *)rowID;
+(id)moveOperationWithRowID:(GloballyUniqueID *)rowID targetRowID:(GloballyUniqueID *)targetRowID;
+(id)undoOperationWithTargetOperationID:(GloballyUniqueID *)targetOpID;
+(id)redoOperationWithTargetOperationID:(GloballyUniqueID *)targetOpID;

// Designated initialiser
-(id)initWithID:(GloballyUniqueID *)opID type:(OperationType)type rowID:(GloballyUniqueID *)rowID targetOperationID:(GloballyUniqueID *)targetOpID targetRowID:(GloballyUniqueID *)targetRowID;

-(id)initInsertOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID;
-(id)initDeleteOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID;
-(id)initMoveOperationWithID:(GloballyUniqueID *)opID rowID:(GloballyUniqueID *)rowID targetRowID:(GloballyUniqueID *)targetRowID;
-(id)initUndoOperationWithID:opID targetOperationID:(GloballyUniqueID *)targetOpID;
-(id)initRedoOperationWithID:opID targetOperationID:(GloballyUniqueID *)targetOpID;

@end
