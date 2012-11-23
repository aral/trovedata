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
-(void)integrateRow:(Row *)row;
-(BOOL)insertRow:(Row *)row;
@end

@interface PostTests ()
@property (nonatomic, strong) Post *post;
@end

@implementation PostTests

-(void) setUp
{
    self.post = [Post new];
}

-(void) tearDown
{
    self.post = nil;
}

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

-(void)testFirstExampleFromWOOTResearchPaperAsSite2
{
    // Simulate generation of op2 at Site 2.
    Fragment *fragment2 = [Fragment fragmentWithType:FragmentTypeText id:[GloballyUniqueID idWithSiteIDString:@"2" localClock:0] data:@{@"text":@"2"}];
    self.post.fragmentPool[fragment2.fragmentID.stringValue] = fragment2;
    // Although the following would test the app better, I want to test that the results are identical to the
    // ones presented in the research paper so I am manually creating this Row so I can control its ID and
    // thus the ID ordering of the various rows.
    // [self.post insertFragmentWithID:fragment2.fragmentID];
    GloballyUniqueID *row2AtSite2ID = [GloballyUniqueID idWithSiteIDString:@"2" localClock:0];
    Row *row2AtSite2 = [Row rowWithContent:fragment2 rowID:row2AtSite2ID previousRowID:self.post.firstRow.selfID nextRowID:self.post.lastRow.selfID];
    self.post.visibleRowStack[0] = row2AtSite2;  // Adding since we generated this locally. It should not affect the test.
    [self.post insertRow:row2AtSite2];  // Adds to row pool and integrates.
    
    // Simulate receipt of op1 from site 1.
    Fragment *fragment1FromSite1 = [Fragment fragmentWithType:FragmentTypeText id:[GloballyUniqueID idWithSiteIDString:@"1" localClock:0] data:@{@"text":@"1"}];
    self.post.fragmentPool[fragment1FromSite1.fragmentID.stringValue] = fragment1FromSite1;
    // Since firstRow and lastRow IDs are constant for all clients,
    // we are just being lazy and using the ones already on the post.
    GloballyUniqueID *row1FromSite1ID = [GloballyUniqueID idWithSiteIDString:@"1" localClock:0];
    Row *row1FromSite1 = [Row rowWithContent:fragment1FromSite1 rowID:row1FromSite1ID previousRowID:self.post.firstRow.selfID nextRowID:self.post.lastRow.selfID];
    self.post.rowPool[row1FromSite1ID.stringValue] = row1FromSite1;
    [self.post integrateRow:row1FromSite1];
    
    // Simulate receipt of op3 from site 3.
    Fragment *fragment3FromSite3 = [Fragment fragmentWithType:FragmentTypeText id:[GloballyUniqueID idWithSiteIDString:@"3" localClock:0] data:@{@"text": @"3"}];
    self.post.fragmentPool[fragment3FromSite3.fragmentID.stringValue] = fragment3FromSite3;
    GloballyUniqueID *row3FromSite3ID = [GloballyUniqueID idWithSiteIDString:@"3" localClock:0];
    Row *row3FromSite3 = [Row rowWithContent:fragment3FromSite3 rowID:row3FromSite3ID previousRowID:self.post.firstRow.selfID nextRowID:row1FromSite1ID];
    self.post.rowPool[row3FromSite3ID.stringValue] = row3FromSite3;
    [self.post integrateRow:row3FromSite3];
    
    // Simulate receipt of op4 from site 3.
    Fragment *fragment4FromSite3 = [Fragment fragmentWithType:FragmentTypeText id:[GloballyUniqueID idWithSiteIDString:@"3" localClock:1] data:@{@"text":@"4"}];
    self.post.fragmentPool[fragment4FromSite3.fragmentID.stringValue] = fragment4FromSite3;
    GloballyUniqueID *row4FromSite3ID = [GloballyUniqueID idWithSiteIDString:@"3" localClock:1];
    Row *row4FromSite3 = [Row rowWithContent:fragment4FromSite3 rowID:row4FromSite3ID previousRowID:row1FromSite1ID nextRowID:self.post.lastRow.selfID];
    self.post.rowPool[row4FromSite3ID.stringValue] = row4FromSite3;
    [self.post integrateRow:row4FromSite3];
    
    NSLog(@"Ordered row stack on Site 2 after integrations: %@", self.post.orderedRowStack);
    
    STAssertEquals(self.post.orderedRowStack.count, (NSUInteger)6, @"There should be six rows in the ordered row stack");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[0]).selfID.stringValue, self.post.firstRow.selfID.stringValue, @"Row 0 should be: the constant first row.");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[1]).selfID.stringValue, row3FromSite3.selfID.stringValue, @"Row 1 should be: Row 3 from site 3 — '3'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[2]).selfID.stringValue, row1FromSite1.selfID.stringValue, @"Row 2 should be: Row 1 from site 1 — '1'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[3]).selfID.stringValue, row2AtSite2.selfID.stringValue, @"Row 3 should be: Row 2 at site 2 — '2'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[4]).selfID.stringValue, row4FromSite3.selfID.stringValue, @"Row 4 should be: Row 4 from site 4 — '4'");
    STAssertEqualObjects(((Row *)self.post.orderedRowStack[5]).selfID.stringValue, self.post.lastRow.selfID.stringValue, @"Row 5 should be: the constant last row.");
    
}


//-(void)testFragmentInsertion
//{
//    Fragment *fragment1 = [Fragment fragmentWithType:FragmentTypeHeading
//                                                  id:[self.post nextFragmentID]
//                                                data:@{@"text":@"Heading 1"}];
//    
//    Fragment *fragment2 = [Fragment fragmentWithType:FragmentTypeText
//                                                  id:[self.post nextFragmentID]
//                                                data:@{@"text":@"Some sample text."}];
//    
//    self.post.fragmentPool[fragment1.fragmentID.stringValue] = fragment1;
//    self.post.fragmentPool[fragment2.fragmentID.stringValue] = fragment2;
//    
//    [self.post insertFragmentWithID:fragment1.fragmentID];
//    [self.post insertFragmentWithID:fragment2.fragmentID];
//
//    NSLog(@"Row pool: %@", self.post.rowPool);
//    
//    Row *rowForFragment1FromOrderedRowStack = (Row *)self.post.orderedRowStack[1];
//    Fragment *shouldBeFragment1FromOrderedRowStack = (Fragment *)rowForFragment1FromOrderedRowStack.content;
//    
//    Row *rowForFragment1FromVisibleRowStack = (Row *)self.post.visibleRowStack[0];
//    Fragment *shouldBeFragment1FromVisibleRowStack = (Fragment *)rowForFragment1FromVisibleRowStack.content;
//    
//    NSLog(@"Row for fragment 1 from ordered row stack: %@", rowForFragment1FromOrderedRowStack);
//    NSLog(@"Row for fragment 1 from visible row stack: %@", rowForFragment1FromVisibleRowStack);
//    
//    
//    STAssertEqualObjects(shouldBeFragment1FromOrderedRowStack.fragmentID.stringValue, fragment1.fragmentID.stringValue, @"First row’s position in the ordered row stack should be correct.");
//    STAssertEqualObjects(shouldBeFragment1FromVisibleRowStack.fragmentID.stringValue, fragment1.fragmentID.stringValue, @"First row’s position in the visible row stack should be correct.");
//    
//}

@end
