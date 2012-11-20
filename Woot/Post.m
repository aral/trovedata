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
#import "Operation.h"
#import "Message.h"

// These are just arbitrary constants. They may change based on perceived usage patterns.
static const NSUInteger kInitialRowPoolCapacity = 100;
static const NSUInteger kInitialOperationPoolCapacity = 100;
static const NSUInteger kInitialBroadcastQueueCapacity = 100;
static const NSUInteger kInitialPendingIntegrationQueueCapacity = 100;
static const NSUInteger kInitialFragmentPoolCapacity = 100;

@interface Post ()
@property (nonatomic, assign) NSUInteger localClockForRows;
@property (nonatomic, assign) NSUInteger localClockForOperations;
@property (nonatomic, strong) Row *firstRow;
@property (nonatomic, strong) Row *lastRow;
@property (nonatomic, strong) Operation *firstOperation;
@property (nonatomic, strong) Operation *lastOperation;
@property (nonatomic, strong) NSString *siteIDString;

// Stacks
@property (nonatomic, strong) NSMutableDictionary *rowPool;
@property (nonatomic, strong) NSMutableArray *operationPool;
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
        self.localClockForRows = 0;
        
        // These are constant on every post, user, device, etc. and used to
        // mark and check for the beginning and end of a post.
        self.firstRow = [Row first];
        self.lastRow = [Row last];
        
        self.firstOperation = [Operation first];
        self.lastOperation = [Operation last];
        
        // Create the row stack, history stack, broadcast queue, and pending integration queue for this document.
        self.rowPool = [NSMutableDictionary dictionaryWithCapacity:kInitialRowPoolCapacity];

        self.operationPool = [NSMutableArray arrayWithCapacity:kInitialOperationPoolCapacity];
        self.historyCursor = 0;
        
        self.broadcastQueue = [NSMutableArray arrayWithCapacity:kInitialBroadcastQueueCapacity];
        self.pendingIntegrationQueue = [NSMutableArray arrayWithCapacity:kInitialPendingIntegrationQueueCapacity];
        self.fragmentPool = [NSMutableDictionary dictionaryWithCapacity:kInitialFragmentPoolCapacity];
    }
    return self;
}

#pragma mark - Local Operations

//
// Inserting a fragment involves creating a row and insertOperation which are added to the
// row and operation pools of the post and the creation of a message that contains the
// fragment ID, row ID, and operation ID to be communicated to be persisted and broadcast to all clients.
//
-(BOOL)insertFragmentWithID:(GloballyUniqueID *)fragmentID betweenRowWithID:(GloballyUniqueID *)previousRowID andRowWithID:(GloballyUniqueID *)nextRowID
{
    // Get the fragment object.
    Fragment *fragment = self.fragmentPool[fragmentID];
    if (fragment == nil) {
        // This should never happen.
        NSLog(@"Error: cannot insert fragment with ID: %@. Fragment not found.", fragmentID);
        return FALSE;
    }
    
    // TODO: Based on the type of the fragment, may need to upload media, etc.
    
    // Create the new row and add it to the row pool.
    GloballyUniqueID *rowID = [self nextRowID];
    Row *row = [Row rowWithContent:fragment rowID:rowID previousRowID:previousRowID nextRowID:nextRowID];
    self.rowPool[rowID.stringValue] = row;
        
    // Create a new insert operation and add it to the operation pool.
    // TODO: Need to pass the previous ID and next ID 
    Operation *insertOperation = [Operation insertOperationWithID:[self nextOperationID] rowID:rowID];
    [self.operationPool addObject:insertOperation];
    
    // Create and add a message to the broadcast queue.
    // TODO: Broadcast the message.
    Message *message = [Message messageWithOperation:insertOperation row:row fragment:fragment];
    [self.broadcastQueue addObject:message];
    
    return TRUE;
}

//
//  Integrate method.
//  =================
//
//  Since the create method will only be called locally (may need to change the name to reflect this better),
//  there is no chance that the previous and next rows will not exist. Keeping this code commented out to
//  remind me to do this check when I implement the remote row insertion method.
//
//  TODO: Check if the previous and next rows exist. If they don’t yet, create a pending integration and
//  push it into the pendingIntegrationQueue.
//
//    Row *previousRow = self.rowPool[previousRowID.stringValue];
//    Row *nextRow = self.rowPool[nextRowID.stringValue];
//
//    if (previousRow && nextRow)
//    {
//        // OK, both previous and next row exist, we can integrate this.
//        // TODO
//    }
//


// TODO: Refactor — there is duplication between op IDs and row IDs.
#pragma mark - Operation ID management

-(GloballyUniqueID *)nextOperationID
{
    self.localClockForOperations++;
    GloballyUniqueID *operationID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:self.localClockForOperations];
    return operationID;
}

-(GloballyUniqueID *)operationIDWithLocalClock:(NSUInteger)localClock
{
    GloballyUniqueID *operationID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:localClock];
    return operationID;
}


#pragma mark - Row ID management

-(GloballyUniqueID *)nextRowID
{
    self.localClockForRows++;
    GloballyUniqueID *rowID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:self.localClockForRows];
    return rowID;
}

-(GloballyUniqueID *)rowIDWithLocalClock:(NSUInteger)localClock
{
    GloballyUniqueID *rowID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:localClock];
    return rowID;
}

@end
