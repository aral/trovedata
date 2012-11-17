//
//  BaseRow.h
//  
//
//  Created by Aral Balkan on 17/11/2012.
//
//

#import <Foundation/Foundation.h>

@class GloballyUniqueID;

@interface BaseRow : NSObject

@property (nonatomic, strong) GloballyUniqueID *selfID;
@property (nonatomic, strong) GloballyUniqueID *previousID;
@property (nonatomic, strong) GloballyUniqueID *nextID;

+(id)first;
+(id)last;

@end
