//
//  TroveSiteID.h
//  Woot
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SiteID : NSObject

@property (nonatomic, strong) NSString *MACAddress;

+ (id)sharedInstance;
- (NSString *)stringValue;
@end
