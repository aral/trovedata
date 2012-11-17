//
//  Message.h
//  TroveData
//
//  Created by Aral Balkan on 17/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Operation;
@class Row;
@class Fragment;

@interface Message : NSObject
@property (nonatomic, strong) Operation *operation;
@property (nonatomic, strong) Row *row;
@property (nonatomic, strong) Fragment *fragment;

+(id)messageWithOperation:(Operation *)operation;
+(id)messageWithOperation:(Operation *)operation row:(Row *)row;
+(id)messageWithOperation:(Operation *)operation row:(Row *)row fragment:(Fragment *)fragment;

-(id)initWithOperation:(Operation *)operation;
-(id)initWithOperation:(Operation *)operation row:(Row *)row;
-(id)initWithOperation:(Operation *)operation row:(Row *)row fragment:(Fragment *)fragment;

@end
