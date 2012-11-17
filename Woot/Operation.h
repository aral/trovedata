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
@property (nonatomic, assign) OperationType type;
@property (nonatomic, strong) GloballyUniqueID *rowID;
@property (nonatomic, strong) GloballyUniqueID *opID;
@property (nonatomic, strong) GloballyUniqueID *targetRowID;
@end
