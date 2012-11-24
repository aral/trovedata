//
//  PostTests.m
//  Woot
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "PostTests.h"
#import "Post.h"
#import "Fragment.h"

//
// Re-implemented here to test the private properties
// (as I don't want to change my actual code just to test it.)
//
#import "GloballyUniqueID.h"
#import "Row.h"
#import "Operation.h"

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

//@property (nonatomic, assign) PostView postView;

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

-(BOOL)insertFragmentWithID:(GloballyUniqueID *)fragmentID;
-(void)integrateInsertRow:(Row *)row;
-(BOOL)insertRow:(Row *)row;
@end

@interface PostTests ()

@property (nonatomic, strong) Post *post;

// Test Helpers

@property (nonatomic, strong) GloballyUniqueID *firstRowID;
@property (nonatomic, strong) GloballyUniqueID *lastRowID;

-(Row *)insertMockRowWithSiteIDString:(NSString *)siteIDString localClock:(NSUInteger)localClock dataString:(NSString *)dataString betweenPreviousRowID:(GloballyUniqueID *)previousRowID andNextRowID:(GloballyUniqueID *)nextRowID;

-(NSString *)stringIDOfOrderedRowAtIndex:(NSUInteger)index;

@end

@implementation PostTests

-(void) setUp
{
    self.post = [Post new];
    self.firstRowID = self.post.firstRow.selfID;
    self.lastRowID = self.post.lastRow.selfID;
}

-(void) tearDown
{
    self.post = nil;
}

#pragma mark - General test helpers

// Inserts and integrates a mock remote row.
-(Row *)insertMockRowWithSiteIDString:(NSString *)siteIDString localClock:(NSUInteger)localClock dataString:(NSString *)dataString betweenPreviousRowID:(GloballyUniqueID *)previousRowID andNextRowID:(GloballyUniqueID *)nextRowID
{
    Fragment *fragment = [Fragment fragmentWithType:FragmentTypeText id:[GloballyUniqueID idWithSiteIDString:siteIDString localClock:localClock] data:@{@"text":dataString}];
    self.post.fragmentPool[fragment.fragmentID.stringValue] = fragment;
    GloballyUniqueID *rowID = [GloballyUniqueID idWithSiteIDString:siteIDString localClock:localClock];
    Row *row = [Row rowWithContent:fragment rowID:rowID previousRowID:previousRowID nextRowID:nextRowID];
    [self.post insertRow:row];  // Adds to row pool and integrates.
    
    return row;
}

-(NSString *)stringIDOfOrderedRowAtIndex:(NSUInteger)index
{
    return ((Row *)self.post.orderedRowStack[index]).selfID.stringValue;
}


#pragma mark - General tests

-(void)testInitialPostStructure
{
    NSString *firstRowIDString = self.post.firstRow.selfID.stringValue;
    NSString *lastRowIDString = self.post.lastRow.selfID.stringValue;
        
    STAssertEqualObjects(firstRowIDString, @"0-0", @"First row ID string should always be '0-0'.");
    STAssertEqualObjects(lastRowIDString, @"0-1", @"Last row ID string should always be '0-1'");

}

-(void)testRowIDOrder
{    
    GloballyUniqueID *id1 = [self.post nextRowID];
    GloballyUniqueID *id2 = [self.post nextRowID];
    
    STAssertTrue(id1.localClock < id2.localClock, @"Local clock of successive fragment IDs should be in ascending order.");
}

-(void)testFragmentInsertion
{
    Fragment *fragment1 = [Fragment fragmentWithType:FragmentTypeHeading
                                                  id:[self.post nextFragmentID]
                                                data:@{@"text":@"Heading 1"}];
    
    Fragment *fragment2 = [Fragment fragmentWithType:FragmentTypeText
                                                  id:[self.post nextFragmentID]
                                                data:@{@"text":@"Some sample text."}];
    
    self.post.fragmentPool[fragment1.fragmentID.stringValue] = fragment1;
    self.post.fragmentPool[fragment2.fragmentID.stringValue] = fragment2;
    
    [self.post insertFragmentWithID:fragment1.fragmentID];
    [self.post insertFragmentWithID:fragment2.fragmentID];
    
//    NSLog(@"Row pool: %@", self.post.rowPool);
    
    Row *rowForFragment1FromOrderedRowStack = (Row *)self.post.orderedRowStack[1];
    Fragment *shouldBeFragment1FromOrderedRowStack = (Fragment *)rowForFragment1FromOrderedRowStack.content;
    
    Row *rowForFragment1FromVisibleRowStack = (Row *)self.post.visibleRowStack[0];
    Fragment *shouldBeFragment1FromVisibleRowStack = (Fragment *)rowForFragment1FromVisibleRowStack.content;
    
//    NSLog(@"Row for fragment 1 from ordered row stack: %@", rowForFragment1FromOrderedRowStack);
//    NSLog(@"Row for fragment 1 from visible row stack: %@", rowForFragment1FromVisibleRowStack);
        
    STAssertEqualObjects(shouldBeFragment1FromOrderedRowStack.fragmentID.stringValue, fragment1.fragmentID.stringValue, @"First row’s position in the ordered row stack should be correct.");
    STAssertEqualObjects(shouldBeFragment1FromVisibleRowStack.fragmentID.stringValue, fragment1.fragmentID.stringValue, @"First row’s position in the visible row stack should be correct.");
    
}

#pragma mark - Example 1 Test Helpers

-(void)runExample1AssertionsWithRow:(Row *)row1 row:(Row *)row2 row:(Row *)row3 row:(Row *)row4
{
    STAssertEquals(self.post.orderedRowStack.count, (NSUInteger)6, @"There should be six rows in the ordered row stack");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[0]).selfID.stringValue, self.post.firstRow.selfID.stringValue, @"Row 0 should be: the constant first row.");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[1]).selfID.stringValue, row3.selfID.stringValue, @"Row 1 should be: Row 3 from site 3 — '3'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[2]).selfID.stringValue, row1.selfID.stringValue, @"Row 2 should be: Row 1 from site 1 — '1'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[3]).selfID.stringValue, row2.selfID.stringValue, @"Row 3 should be: Row 2 at site 2 — '2'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[4]).selfID.stringValue, row4.selfID.stringValue, @"Row 4 should be: Row 4 from site 4 — '4'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[5]).selfID.stringValue, self.post.lastRow.selfID.stringValue, @"Row 5 should be: the constant last row.");
}

#pragma mark - Example 1 Tests

//
// Section 3.5, Pg. 11: Example 1 from
// Real time group editors without Operational transformation
// Gérald Oster — Pascal Urso — Pascal Molli — Abdessamad Imine
// Mai 2005
//
// Hasse diagram:
//
//    __ 2 __
//   /       \
//  /         \
// Cb -- 1 -- Ce
//  \   / \   /
//   \ /   \ /
//    3     4
//

-(void)testFirstExampleAsSite2
{
    // Example 1 as Site 2.
    
    // Site 2 — new row generated: ins(Cb < 2 < Ce)
    Row *row2 = [self insertMockRowWithSiteIDString:@"2" localClock:0 dataString:@"2" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    // Remote row received from Site 1: ins(Cb < 1 < Ce)
    Row *row1 = [self insertMockRowWithSiteIDString:@"1" localClock:0 dataString:@"1" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    // Remote row received from Site 3: ins(Cb < 3 < 1)
    Row *row3 = [self insertMockRowWithSiteIDString:@"3" localClock:0 dataString:@"3" betweenPreviousRowID:self.firstRowID andNextRowID:row1.selfID];
    
    // Remote row received from Site 3: ins(1 < 4 < Ce)
    Row *row4 = [self insertMockRowWithSiteIDString:@"3" localClock:1 dataString:@"4" betweenPreviousRowID:row1.selfID andNextRowID:self.lastRowID];
    
    [self runExample1AssertionsWithRow:row1 row:row2 row:row3 row:row4];
    
}

-(void)testFirstExampleAsSite3
{
    //
    // Example 1 as Site 3.
    //
    
    // Remote row received from Site 1: ins(Cb < 1 < Ce)
    Row *row1 = [self insertMockRowWithSiteIDString:@"1" localClock:0 dataString:@"1" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    // Site 3 — new row generated: ins(Cb < 3 < 1)
    Row *row3 = [self insertMockRowWithSiteIDString:@"3" localClock:0 dataString:@"3" betweenPreviousRowID:self.firstRowID andNextRowID:row1.selfID];
    
    // Site 3 — new row generated: ins(1 < 4 < Ce)
    Row *row4 = [self insertMockRowWithSiteIDString:@"3" localClock:1 dataString:@"4" betweenPreviousRowID:row1.selfID andNextRowID:self.lastRowID];
    
    // Remote row received from Site 2: ins(Cb < 2 < Ce)
    Row *row2 = [self insertMockRowWithSiteIDString:@"2" localClock:0 dataString:@"2" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    [self runExample1AssertionsWithRow:row1 row:row2 row:row3 row:row4];
}

-(void)testFirstExampleAsSite1
{
    //
    // Example 1 as Site 1.
    //
    // Extension of example in research paper: assuming order o1, o2, o3, o4.
    //
    
    // Site 1 — new row generated: ins(Cb < 1 < Ce)
    Row *row1 = [self insertMockRowWithSiteIDString:@"1" localClock:0 dataString:@"1" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    // Remote row received from Site 2: ins(Cb < 2 < Ce)
    Row *row2 = [self insertMockRowWithSiteIDString:@"2" localClock:0 dataString:@"2" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    // Remote row received from Site 3: ins(Cb < 3 < 1)
    Row *row3 = [self insertMockRowWithSiteIDString:@"3" localClock:0 dataString:@"3" betweenPreviousRowID:self.firstRowID andNextRowID:row1.selfID];
    
    // Remote row received from Site 3: ins(1 < 4 < Ce)
    Row *row4 = [self insertMockRowWithSiteIDString:@"3" localClock:1 dataString:@"4" betweenPreviousRowID:row1.selfID andNextRowID:self.lastRowID];
    
    [self runExample1AssertionsWithRow:row1 row:row2 row:row3 row:row4];
}

#pragma mark - Example 2 Test Helpers

-(NSArray *)commonlyReceivedRowsForExample2
{
    Row *row0 = [self insertMockRowWithSiteIDString:@"1" localClock:0 dataString:@"0" betweenPreviousRowID:self.firstRowID andNextRowID:self.lastRowID];
    
    Row *row1 = [self insertMockRowWithSiteIDString:@"2" localClock:0 dataString:@"1" betweenPreviousRowID:self.firstRowID andNextRowID:row0.selfID];
    
    Row *row2 = [self insertMockRowWithSiteIDString:@"3" localClock:0 dataString:@"2" betweenPreviousRowID:self.firstRowID andNextRowID:row0.selfID];
    
    Row *row3 = [self insertMockRowWithSiteIDString:@"4" localClock:0 dataString:@"3" betweenPreviousRowID:row0.selfID andNextRowID:self.lastRowID];
    
    Row *row4 = [self insertMockRowWithSiteIDString:@"5" localClock:0 dataString:@"4" betweenPreviousRowID:row0.selfID andNextRowID:self.lastRowID];
    
    NSArray *rows = @[row0, row1, row2, row3, row4];
    
    return rows;
}

-(void)runExample2AssertsUsingRowArray:(NSArray *)rows
{
    STAssertEquals(self.post.orderedRowStack.count, (NSUInteger)9, @"There should be nine rows in the ordered row stack");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:0], self.firstRowID.stringValue, @"RB");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:1], ((Row *)rows[1]).selfID.stringValue, @"1");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:2], ((Row *)rows[2]).selfID.stringValue, @"2");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:3], ((Row *)rows[0]).selfID.stringValue, @"0");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:4], ((Row *)rows[6]).selfID.stringValue, @"6");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:5], ((Row *)rows[3]).selfID.stringValue, @"3");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:6], ((Row *)rows[5]).selfID.stringValue, @"5");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:7], ((Row *)rows[4]).selfID.stringValue, @"4");
    STAssertEqualObjects([self stringIDOfOrderedRowAtIndex:8], self.lastRowID.stringValue, @"RE");
}

#pragma mark - Example 2 Tests

//
// Section 3.5, Pg. 13: Example 2 from
// Real time group editors without Operational transformation
// Gérald Oster — Pascal Urso — Pascal Molli — Abdessamad Imine
// Mai 2005
//
// Hasse diagram:
//
//       6
//      / \
//     /   \
//    1     3
//   / \   / \
//  /   \ /   \
// Cb -- 0 -- Ce
//  \   / \   /
//   \ /   \ /
//    2     4
//     \   /
//      \ /
//       5
//

-(void)testReceptionOfRow6Then5
{
    NSMutableArray *rows = [[self commonlyReceivedRowsForExample2] mutableCopy];
    
    Row *row6 = [self insertMockRowWithSiteIDString:@"7" localClock:0 dataString:@"6" betweenPreviousRowID:((Row *)rows[1]).selfID andNextRowID:((Row *)rows[3]).selfID];
    
    Row *row5 = [self insertMockRowWithSiteIDString:@"6" localClock:0 dataString:@"5" betweenPreviousRowID:((Row *)rows[2]).selfID andNextRowID:((Row *)rows[4]).selfID];

    [rows addObject:row5];
    [rows addObject:row6];
    
    [self runExample2AssertsUsingRowArray:[rows copy]];
}

-(void)testReceptionOfRow5Then6
{
    NSMutableArray *rows = [[self commonlyReceivedRowsForExample2] mutableCopy];
    
    Row *row5 = [self insertMockRowWithSiteIDString:@"6" localClock:0 dataString:@"5" betweenPreviousRowID:((Row *)rows[2]).selfID andNextRowID:((Row *)rows[4]).selfID];

    Row *row6 = [self insertMockRowWithSiteIDString:@"7" localClock:0 dataString:@"6" betweenPreviousRowID:((Row *)rows[1]).selfID andNextRowID:((Row *)rows[3]).selfID];
    
    [rows addObject:row5];
    [rows addObject:row6];
    
    [self runExample2AssertsUsingRowArray:[rows copy]];
}

@end
