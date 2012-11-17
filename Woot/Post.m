//
//  Post
//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "Post.h"
#import "GloballyUniqueID.h"
#import "Row.h"
#import "SiteID.h"
#import "Fragment.h"

// These are just arbitrary constants. They may change based on perceived usage patterns.
static const NSUInteger kInitialRowPoolCapacity = 100;
static const NSUInteger kInitialHistoryStackCapacity = 100;
static const NSUInteger kInitialBroadcastQueueCapacity = 100;
static const NSUInteger kInitialPendingIntegrationQueueCapacity = 100;
static const NSUInteger kInitialFragmentPoolCapacity = 100;

@interface Post ()
@property (nonatomic, assign) NSUInteger localClock;
@property (nonatomic, strong) Row *firstRow;
@property (nonatomic, strong) Row *lastRow;
@property (nonatomic, strong) NSString *siteIDString;

// Stacks
@property (nonatomic, strong) NSMutableDictionary *rowPool;
@property (nonatomic, strong) NSMutableArray *historyStack;
@property (nonatomic, strong) NSMutableArray *broadcastQueue;
@property (nonatomic, strong) NSMutableArray *pendingIntegrationQueue;
@property (nonatomic, strong) NSMutableDictionary *fragmentPool;

@property (nonatomic, assign) NSUInteger historyCursor;

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
        
        // Create the row stack, history stack, broadcast queue, and pending integration queue for this document.
        self.rowPool = [NSMutableDictionary dictionaryWithCapacity:kInitialRowPoolCapacity];

        self.historyStack = [NSMutableArray arrayWithCapacity:kInitialHistoryStackCapacity];
        self.historyCursor = 0;
        
        self.broadcastQueue = [NSMutableArray arrayWithCapacity:kInitialBroadcastQueueCapacity];
        self.pendingIntegrationQueue = [NSMutableArray arrayWithCapacity:kInitialPendingIntegrationQueueCapacity];
        self.fragmentPool = [NSMutableDictionary dictionaryWithCapacity:kInitialFragmentPoolCapacity];
    }
    return self;
}

#pragma mark - Operations

-(BOOL)createNewRowForFragmentWithID:(GloballyUniqueID *)fragmentID betweenRowWithID:(GloballyUniqueID *)previousRowID andRowWithID:(GloballyUniqueID *)nextRowID
{
    // Get the fragment object.
    Fragment *fragment = self.fragmentPool[fragmentID];
    if (fragment == nil) {
        NSLog(@"Error: cannot insert fragment with ID: %@. Fragment not found.", fragmentID);
        return FALSE;
    }
    
    // Create the new row and add it to the row pool.
    GloballyUniqueID *rowID = [self nextRowID];
    Row *row = [Row rowWithContent:fragment rowID:rowID previousRowID:previousRowID nextRowID:nextRowID];
    self.rowPool[rowID.stringValue] = row;
    
    // TODO: Check if the previous and next rows exist. If they don’t yet, create a pending integration and
    // push it into the pendingIntegrationQueue.
    Row *previousRow = self.rowPool[previousRowID.stringValue];
    Row *nextRow = self.rowPool[nextRowID.stringValue];
    
//   Since the create method will only be called locally (may need to change the name to reflect this better),
//   there is no chance that the previous and next rows will not exist. Keeping this code commented out to
//   remind me to do this check when I implement the remote row insertion method.
//    if (previousRow && nextRow)
//    {
//        // OK, both previous and next row exist, we can integrate this.
//        // TODO
//    }
    
    // TODO: Create a new insert operation and add it to the history stack.
    
    // TODO: Create and add a message to the broadcast queue.
    
    return TRUE;
}

#pragma mark - Row ID management

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
