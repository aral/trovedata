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

@property (nonatomic, strong) GloballyUniqueID *rowID;

+(id)first;
+(id)last;

@end
