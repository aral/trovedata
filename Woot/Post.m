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
static const NSUInteger kInitialOrderedRowStackCapactity = 100;
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
@property (nonatomic, strong) NSMutableArray *orderedRowStack;
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

-(void)integrateRow:(Row *)row;

-(BOOL)insertFragmentWithID:(GloballyUniqueID *)fragmentID;
-(BOOL)insertRow:(Row *)row;
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
        self.rowPool[self.firstRow.selfID.stringValue] = self.firstRow;
        self.rowPool[self.lastRow.selfID.stringValue] = self.lastRow;
        
        self.operationPool = [NSMutableDictionary dictionaryWithCapacity:kInitialOperationPoolCapacity];
        self.historyCursor = 0;

        self.fragmentPool = [NSMutableDictionary dictionaryWithCapacity:kInitialFragmentPoolCapacity];
        
        self.orderedRowStack = [NSMutableArray arrayWithCapacity:kInitialOrderedRowStackCapactity];
        
        [self.orderedRowStack addObject:self.firstRow];
        [self.orderedRowStack addObject:self.lastRow];
        
        self.visibleRowStack = [NSMutableArray arrayWithCapacity:kInitialVisibleRowStackCapacity];
        self.broadcastQueue = [NSMutableArray arrayWithCapacity:kInitialBroadcastQueueCapacity];
        self.pendingIntegrationQueue = [NSMutableArray arrayWithCapacity:kInitialPendingIntegrationQueueCapacity];

    }
    return self;
}

#pragma mark - Remote Operations
-(void)integrateRow:(Row *)row
{
    // Integrate a remotely‐received row
    NSLog(@"About to integrate remotely‐received row: %@", row);
    [self integrateRow:row betweenID:row.previousID andID:row.nextID];
}

#pragma mark - Local Operations

-(BOOL)isID:(GloballyUniqueID *)firstID lessThanID:(GloballyUniqueID *)secondID
{
    BOOL result;
    if ([firstID.siteID isEqualTo:secondID.siteID])
    {
        BOOL isFirstRow = [firstID.stringValue isEqualToString: ((Row *)[Row first]).selfID.stringValue];
        result = isFirstRow || (firstID.localClock < secondID.localClock);
    }
    else
    {
        NSComparisonResult comparisonResult = [firstID.siteID compare: secondID.siteID];
        NSAssert(comparisonResult != NSOrderedSame, @"Globally unique IDs from different sites should never be the same.");
        result = comparisonResult == NSOrderedAscending;
    }
    return result;
}


-(BOOL)isID:(GloballyUniqueID *)firstID greaterThanID:(GloballyUniqueID *)secondID
{
    BOOL result;
    if ([firstID.siteID isEqualTo:secondID.siteID])
    {
        BOOL isLastRow = [firstID.stringValue isEqualToString: ((Row *)[Row last]).selfID.stringValue];
        result = isLastRow || (firstID.localClock > secondID.localClock);
    }
    else
    {
        NSComparisonResult comparisonResult = [firstID.siteID compare: secondID.siteID];
        NSAssert(comparisonResult != NSOrderedSame, @"Globally unique IDs from different sites should never be the same.");
        result = comparisonResult == NSOrderedDescending;
    }
    return result;
}

// Recursive method that integrates the row into the visible
-(void)integrateRow:(Row *)row betweenID:(GloballyUniqueID *)previousID andID:(GloballyUniqueID *)nextID
{
    NSLog(@"Integrate row called with row: %@ between ID: %@ and ID: %@", row, previousID, nextID);
    
    // (Cannot be larger than the number of rows in the ordered row stack)
    
    Row *previousRow = self.rowPool[previousID.stringValue];
    Row *nextRow = self.rowPool[nextID.stringValue];
    
    NSLog(@"Previous row: %@", previousRow);
    NSLog(@"Next row: %@", nextRow);
    
    NSInteger indexOfPreviousRowInOrderedRowStack = [self.orderedRowStack indexOfObject:previousRow];
    NSInteger indexOfNextRowInOrderedRowStack = [self.orderedRowStack indexOfObject:nextRow];
    
    NSLog(@"Current state of ordered row stack: %@", self.orderedRowStack);
//    NSLog(@"Row pool: %@", self.rowPool);
    NSLog(@"Index of previous row in ordered row stack = %lu", indexOfPreviousRowInOrderedRowStack);
    NSLog(@"Index of next row in ordered row stack = %lu", indexOfNextRowInOrderedRowStack);
    
    NSRange rangeOfInterest = NSRangeFromString([NSString stringWithFormat:@"%lu, %lu", indexOfPreviousRowInOrderedRowStack+1, indexOfNextRowInOrderedRowStack-indexOfPreviousRowInOrderedRowStack-1]);
    
    // Create the list of rows that initially interest us for use in ordering.
    // (In the WOOT research paper, this list is denoated by S'.)
    NSArray *rowsBetweenPreviousRowAndNextRow = [self.orderedRowStack subarrayWithRange:rangeOfInterest];
    
    NSLog(@"S' = %@", rowsBetweenPreviousRowAndNextRow);
    
    // TODO: Check if the S' array is empty. And if so, insert the character between previousID and nextID
    NSUInteger numberOfrowsBetweenPreviousRowAndNextRow = rowsBetweenPreviousRowAndNextRow.count;
    if (numberOfrowsBetweenPreviousRowAndNextRow == 0)
    {
        NSLog(@"numberOfrowsBetweenPreviousRowAndNextRow = 0… about to insert row.");
        
        // Insert row into the ordered row stack.
        Row *rowToInsertRowAt = self.rowPool[nextID.stringValue];
        NSUInteger indexToInsertTheRow = [self.orderedRowStack indexOfObject:rowToInsertRowAt];
        NSLog(@"Index to insert the row: %lu", indexToInsertTheRow);
        [self.orderedRowStack insertObject:row atIndex:indexToInsertTheRow];
        
        NSLog(@"Inserted row %@ at index: %lu", row, indexToInsertTheRow);
        NSLog(@"Ordered row stack: %@", self.orderedRowStack);
        
        return;
    }
    
    NSLog(@"About to filter S'");
    
    // (In the WOOT research paper, this array is denoted by L.)
    //
    // The +2 is to make room for the previous and next rows which bookend
    // the filtered list as per the algorithm in the WOOT research paper.
    //
    // L = Cpd0d1d2...dmCn where d0...dm are the rows in S' such that
    //     Cp(di) <=(s) Cp and Cn <=(s) Cn(di)
    //
    NSMutableArray *filteredArray = [NSMutableArray arrayWithCapacity:rowsBetweenPreviousRowAndNextRow.count + 2];
    [filteredArray addObject:previousRow];
    
    for (Row *currentRow in rowsBetweenPreviousRowAndNextRow)
    {
        NSLog(@"About to filter row: %@", currentRow);
        
        // We get the current previous and next rows from the row pool and don’t use the currentRow.previousID and
        // currentRow.nextID objects directly as they may not be the same ID object if received from a remote source.
        NSLog(@"Current Previous Row ID: %@", currentRow.previousID.stringValue);
        NSLog(@"Current Next Row ID: %@", currentRow.nextID.stringValue);
        
        Row *currentPreviousRow = self.rowPool[currentRow.previousID.stringValue];
        Row *currentNextRow = self.rowPool[currentRow.nextID.stringValue];
        
        NSUInteger indexOfCurrentPreviousRowInOrderedRowStack = [self.orderedRowStack indexOfObject:currentPreviousRow];
        NSUInteger indexOfCurrentNextRowInOrderedRowStack = [self.orderedRowStack indexOfObject:currentNextRow];
        
        NSLog(@"Index of current previus row in ordered row stack: %lu", indexOfCurrentPreviousRowInOrderedRowStack);
        NSLog(@"Index of current next row in ordered row stack: %lu", indexOfCurrentNextRowInOrderedRowStack);
        
        // Only include the current row if its previous row ID is less than or equal to the row-being-integrated’s
        // previous row ID and if its next row ID is greater than or equal to the row‐being‐integrated’s next row ID. 
        BOOL previousOrderingCheck = indexOfCurrentPreviousRowInOrderedRowStack <= indexOfPreviousRowInOrderedRowStack;
        BOOL nextOrderingCheck = indexOfCurrentNextRowInOrderedRowStack >= indexOfNextRowInOrderedRowStack;
        
        NSLog(@"Previous ordering check: %lu <= %lu = %@", indexOfCurrentPreviousRowInOrderedRowStack, indexOfPreviousRowInOrderedRowStack, previousOrderingCheck ? @"YES" : @"NO");
        NSLog(@"Next ordering check: %lu <= %lu = %@", indexOfCurrentNextRowInOrderedRowStack, indexOfNextRowInOrderedRowStack, nextOrderingCheck ? @"YES" : @"NO");
        
        // This row statisfies the ordering rules. Add it to the resulting array.
        if (previousOrderingCheck && nextOrderingCheck)
        {
            [filteredArray addObject:currentRow];
        }
    }
    
    [filteredArray addObject:nextRow];
    
    NSLog(@"L = %@", filteredArray);
    
    // Check for ID ordering in the latest list
    // (None of the examples in the WOOT research paper end up with an L that has more
    // than one element but I can see how this can happen so I’m implementing this as per the
    // algorithm in the original paper.)
    // TODO: Create test case for when there is more than one row.
    NSInteger i = 1;
    NSInteger indexOfLastRowInFilteredArray = filteredArray.count - 1;
    NSLog(@"Index of last row in array: %li", indexOfLastRowInFilteredArray);
    NSLog(@"%li < %li ? %@", i, indexOfLastRowInFilteredArray, i < indexOfLastRowInFilteredArray ? @"YES": @"NO");
    NSLog(@"Getting the index to recurse on…");
    NSLog(@"About to check that %@ is less than %@", ((Row *)filteredArray[i]).selfID, row.selfID);
    while ( (i < indexOfLastRowInFilteredArray) && [self isID:((Row *)filteredArray[i]).selfID lessThanID:row.selfID] )
    {
        NSLog(@"It is less, incremening i…");
        i++;
        NSLog(@"i = %lu",i);
        NSLog(@"About to check that %@ is less than %@", ((Row *)filteredArray[i]).selfID, row.selfID);
    }
    NSLog(@"It is not less! Stopped.");
    
    GloballyUniqueID *newPreviousID = ((Row *)filteredArray[i-1]).selfID;
    GloballyUniqueID *newNextID = ((Row *)filteredArray[i]).selfID;
    
    NSLog(@"New Previous ID = %@", newPreviousID);
    NSLog(@"New Next ID = %@", newNextID);
    NSLog(@"About to recurse…");
    
    // DEBUG
    if (filteredArray.count == 2) {
        if ([((Row *)filteredArray[0]).selfID isEqual:self.firstRow.selfID] && [((Row *)filteredArray[1]).selfID isEqual: self.lastRow.selfID]) {
            NSAssert(FALSE, @"ENDLESS LOOP!!!!");
        }
    }
    
    // Recurse to integrate the new array after initial ordering
    [self integrateRow:row betweenID:newPreviousID andID:newNextID];
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
    
    // Integrate the row into the ordered row list
    [self integrateRow:row betweenID:row.previousID andID:row.nextID];
    
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
    
    // Insert the row in the visible row stack
    self.visibleRowStack[visibleRowIndex] = row;
    
    // Insert the row into the row pool and make sure it gets integrated.
    [self insertRow:row];
    
    // Create a new insert operation and add it to the operation pool.
    // TODO: Need to pass the previous ID and next ID 
//    Operation *insertOperation = [Operation insertOperationWithID:[self nextOperationID] rowID:rowID];
//    self.operationPool[insertOperation.selfID.stringValue] = insertOperation;
    
    // Create and add a message to the broadcast queue.
    // TODO: Broadcast the message.
//    Message *message = [Message messageWithOperation:insertOperation row:row fragment:fragment];
//    [self.broadcastQueue addObject:message];
    
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
