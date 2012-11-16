//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

//static NSString const *

@class GloballyUniqueID;

@interface Row : NSObject

@property (nonatomic, strong) GloballyUniqueID *rowID;
@property (nonatomic, strong) id content;
@property (nonatomic, assign) NSInteger visibilityDegree;
@property (nonatomic, strong) GloballyUniqueID *previousRowID;
@property (nonatomic, strong) GloballyUniqueID *nextRowID;

+(id)firstRow;
+(id)lastRow;

@end
