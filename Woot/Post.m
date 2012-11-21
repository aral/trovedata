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
static const NSUInteger kInitialFragmentPoolCapacity = 100;

static const NSUInteger kInitialVisibleRowStackCapacity = 100;
static const NSUInteger kInitialBroadcastQueueCapacity = 100;
static const NSUInteger kInitialPendingIntegrationQueueCapacity = 100;

// The current view of the post (client‐specific)
typedef enum {
    PostViewDocument,
    PostViewStream
} PostView;


@interface Post ()

// TODO: Maybe move this to the GloballyUniqueID class?
@property (nonatomic, assign) NSUInteger localClockForRows;
@property (nonatomic, assign) NSUInteger localClockForOperations;
@property (nonatomic, assign) NSUInteger localClockForFragments;

@property (nonatomic, strong) Row *firstRow;
@property (nonatomic, strong) Row *lastRow;
@property (nonatomic, strong) Operation *firstOperation;
@property (nonatomic, strong) Operation *lastOperation;
@property (nonatomic, strong) NSString *siteIDString;

@property (nonatomic, assign) PostView postView;

// Pools
@property (nonatomic, strong) NSMutableDictionary *rowPool;
@property (nonatomic, strong) NSMutableDictionary *operationPool;
@property (nonatomic, strong) NSMutableDictionary *fragmentPool;

// Stacks
@property (nonatomic, strong) NSMutableArray *visibleRowStack;
@property (nonatomic, strong) NSMutableArray *broadcastQueue;
@property (nonatomic, strong) NSMutableArray *pendingIntegrationQueue;

// Used with the operation pool to stack current position in history for undo/redo.
@property (nonatomic, assign) NSUInteger historyCursor;

// TODO: refactor this.
-(GloballyUniqueID *)nextRowID;
-(GloballyUniqueID *)rowIDWithLocalClock:(NSUInteger)localClock;
-(GloballyUniqueID *)nextFragmentID;
-(GloballyUniqueID *)fragmentIDWithLocalClock:(NSUInteger)localClock;
-(GloballyUniqueID *)nextOperationID;
-(GloballyUniqueID *)operationIDWithLocalClock:(NSUInteger)localClock;

-(BOOL)insertFragmentWithID:(GloballyUniqueID *)fragmentID;

@end

@implementation Post

-(id)init
{
    self = [super init];
    if (self) {
        self.siteIDString = [[SiteID sharedInstance] stringValue];
        self.localClockForRows = 0;
        
        self.postView = PostViewDocument;
        
        // These are constant on every post, user, device, etc. and used to
        // mark and check for the beginning and end of a post.
        self.firstRow = [Row first];
        self.lastRow = [Row last];
        
        self.firstOperation = [Operation first];
        self.lastOperation = [Operation last];
        
        // Create the row stack, history stack, broadcast queue, and pending integration queue for this document.
        self.rowPool = [NSMutableDictionary dictionaryWithCapacity:kInitialRowPoolCapacity];
        
        self.operationPool = [NSMutableDictionary dictionaryWithCapacity:kInitialOperationPoolCapacity];
        self.historyCursor = 0;

        self.fragmentPool = [NSMutableDictionary dictionaryWithCapacity:kInitialFragmentPoolCapacity];
        
        self.visibleRowStack = [NSMutableArray arrayWithCapacity:kInitialVisibleRowStackCapacity];
        self.broadcastQueue = [NSMutableArray arrayWithCapacity:kInitialBroadcastQueueCapacity];
        self.pendingIntegrationQueue = [NSMutableArray arrayWithCapacity:kInitialPendingIntegrationQueueCapacity];

    }
    return self;
}

#pragma mark - Local Operations

-(void)render
{
    NSLog(@"Rendering…");
    
    // Clear the visible view stack
    [self.visibleRowStack removeAllObjects];

    // Iterate over all rows starting with the first and add the
    // visible ones to the visible row stack.
    Row *currentRow = self.firstRow;
    while (![currentRow.nextID.stringValue isEqualToString:self.lastRow.selfID.stringValue]) {
        
        NSLog(@"Current row: %@", currentRow);
        NSLog(@"currentRow.visibilityDegree = %lu", currentRow.visibilityDegree);
        
        if (currentRow.visibilityDegree == kRowVisible)
        {
            NSLog(@"Current row visible, adding to visible row stack…");
            [self.visibleRowStack addObject:currentRow];
        }
        
        currentRow = self.rowPool[currentRow.nextID];
        
        NSAssert(currentRow !=  nil, @"Current row should not be nil.");
        
        NSLog(@"New current row: %@", currentRow);
    }
    
    // If we are in stream mode, reverse the visible view stack.
    if (self.postView == PostViewStream) {
        // If in stream view, reverse the list.
        self.visibleRowStack = [[[self.visibleRowStack reverseObjectEnumerator] allObjects] mutableCopy];
    }
    
    NSLog(@"Visible row stack after render: %@", self.visibleRowStack);
}

// Adds row to the row pool
-(BOOL)insertRow:(Row *)row
{
    NSLog(@"Inserting row %@", row);
    
    if (self.rowPool[row.selfID.stringValue] != nil)
    {
        NSLog(@"Warning, the row is already in the row pool. Not adding again. %@", row);
        return FALSE;
    }
    
    self.rowPool[row.selfID.stringValue] = row;
    
    NSLog(@"Inserted row with ID %@ into the row pool.", row.selfID.stringValue);
    
    if (row.visibilityDegree == kRowVisible)
    {
        NSLog(@"Row is visible, rendering visible view stack");
        [self render];
    }
    
    return TRUE;
}

//
// Helper method, pushes row.
//
-(BOOL)insertFragmentWithID:(GloballyUniqueID *)fragmentID
{
    return [self insertFragmentWithID:fragmentID atVisibleRowIndex:self.visibleRowStack.count];
}

// TODO: Create a createFragment method that makes a fragment when passed a fragment type. 

//
// Inserting a fragment involves creating a row and insertOperation which are added to the
// row and operation pools of the post and the creation of a message that contains the
// fragment ID, row ID, and operation ID to be communicated to be persisted and broadcast to all clients.
//
-(BOOL)insertFragmentWithID:(GloballyUniqueID *)fragmentID atVisibleRowIndex:(NSInteger)visibleRowIndex
{
    NSLog(@"About to insert a new fragment at index: %lu", visibleRowIndex);
    
    // Get the fragment object.
    Fragment *fragment = self.fragmentPool[fragmentID.stringValue];
    if (fragment == nil) {
        // This should never happen.
        NSLog(@"Error: cannot insert fragment with ID: %@. Fragment not found.", fragmentID);
        return FALSE;
    }
    
    // TODO: Based on the type of the fragment, may need to upload media, etc.

    // TODO: Should we actually do the insert here or elsewhere?
    
    // Find the row IDs for the previous visible row and the next visible row to insert this row in between.
    GloballyUniqueID *previousRowID = nil;
    GloballyUniqueID *nextRowID = nil;

    // Set the previous ID, based on the previous row in the visible stack.
    if (visibleRowIndex-1 >= 0)
    {
        Row *previousVisibleRow = self.visibleRowStack[visibleRowIndex-1];
        previousRowID = previousVisibleRow.selfID;
    }
    else
    {
        previousRowID = self.firstRow.selfID;
    }
    
    if (visibleRowIndex+1 < self.visibleRowStack.count)
    {
        Row *nextVisibleRow = self.visibleRowStack[visibleRowIndex+1];
        nextRowID = nextVisibleRow.selfID;
    }
    else
    {
        nextRowID = self.lastRow.selfID;
    }

    NSLog(@"Previous row ID: %@", previousRowID.stringValue);
    NSLog(@"Next row ID: %@", nextRowID.stringValue);
    
    // Create the new row and add it to the row pool.
    GloballyUniqueID *rowID = [self nextRowID];
    Row *row = [Row rowWithContent:fragment rowID:rowID previousRowID:previousRowID nextRowID:nextRowID];
    [self insertRow:row];
    
    // Create a new insert operation and add it to the operation pool.
    // TODO: Need to pass the previous ID and next ID 
    Operation *insertOperation = [Operation insertOperationWithID:[self nextOperationID] rowID:rowID];
    self.operationPool[insertOperation.selfID.stringValue] = insertOperation;
    
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
#pragma mark - Fragment ID management

-(GloballyUniqueID *)nextFragmentID
{
    self.localClockForRows++;
    GloballyUniqueID *fragmentID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:self.localClockForFragments];
    return fragmentID;
}

-(GloballyUniqueID *)fragmentIDWithLocalClock:(NSUInteger)localClock
{
    GloballyUniqueID *fragmentID = [GloballyUniqueID idWithSiteIDString:self.siteIDString localClock:localClock];
    return fragmentID;
}


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
