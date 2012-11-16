//
//  WootSequence.m
//  Woot
//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "Post.h"
#import "GloballyUniqueID.h"
#import "Row.h"
#import "SiteID.h"

@interface Post ()
@property (nonatomic, assign) NSUInteger localClock;
@property (nonatomic, strong) Row *firstRow;
@property (nonatomic, strong) Row *lastRow;
@property (nonatomic, strong) NSString *siteIDString;
-(GloballyUniqueID *)nextRowID;
-(GloballyUniqueID *)rowIDWithLocalClock:(NSUInteger)localClock;
@end

@implementation Post

-(id)init
{
    self = [super init];
    if (self) {
        self.siteIDString = [[SiteID sharedInstance] stringValue];
        self.localClock = 0;
        
        // These are constant on every post, user, device, etc. and used to
        // mark and check for the beginning and end of a post.
        self.firstRow = [Row firstRow];
        self.lastRow = [Row lastRow];
        
        // TODO: Create the row stack, history stack, broadcast queue, and pending queue for this document.
    }
    return self;
}

#pragma mark - Fragment ID management

-(GloballyUniqueID *)nextRowID
{
    self.localClock++;
    GloballyUniqueID *rowID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:self.localClock];
    return rowID;
}

-(GloballyUniqueID *)rowIDWithLocalClock:(NSUInteger)localClock
{
    GloballyUniqueID *rowID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:localClock];
    return rowID;
}

@end
