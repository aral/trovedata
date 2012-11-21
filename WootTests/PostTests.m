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
    
    NSLog(@"First row ID: %@", firstRowIDString);
    NSLog(@"Last row ID: %@", lastRowIDString);
    
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
    
    NSLog(@"Row pool: %@", self.post.rowPool);
    NSLog(@"About to check for %@", self.post.firstRow.nextID.stringValue);
    
    Row *rowForFragment1 = (Row *)self.post.rowPool[self.post.firstRow.nextID.stringValue];
    Fragment *shouldBeFragment1 = (Fragment *)rowForFragment1.content;
    
    NSLog(@"Row for fragment 1: %@", rowForFragment1);
    
    STAssertEqualObjects(shouldBeFragment1.fragmentID.stringValue, fragment1.fragmentID.stringValue, @"The first row's next row should contain the first fragment.");
    
}

@end
