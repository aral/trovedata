//
//  Fragment.h
//  Woot
//
//  Created by Aral Balkan on 16/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GloballyUniqueID.h"

typedef enum {
    FragmentTypeHeading = 1,
    FragmentTypeText = 2,
    FragmentTypeImage = 3,
    FragmentTypeTweet = 4
} FragmentType;

@interface Fragment : NSObject

@property (nonatomic, strong) GloballyUniqueID *fragmentID;
@property (nonatomic, assign) FragmentType type;
@property (nonatomic, strong) NSDictionary *data;

-(id)initFragmentWithType:(FragmentType)fragmentType id:(GloballyUniqueID *)fragmentID data:(NSDictionary *)data;

@end
