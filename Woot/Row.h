//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

//static NSString const *

@class GloballyUniqueID;

#import "BaseRow.h"

@interface Row : BaseRow

@property (nonatomic, strong) id content;
@property (nonatomic, strong) GloballyUniqueID *previousRowID;
@property (nonatomic, strong) GloballyUniqueID *nextRowID;
@property (nonatomic, assign) NSInteger visibilityDegree;


+(id)rowWithContent:(id)content rowID:(GloballyUniqueID *)rowID previousRowID:(GloballyUniqueID *)previousRowID nextRowID:(GloballyUniqueID *)nextRowID;
-(id)initWithContent:(id)content rowID:(GloballyUniqueID *)rowID previousRowID:(GloballyUniqueID *)previousRowID nextRowID:(GloballyUniqueID *)nextRowID;

@end
