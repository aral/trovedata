//
//  PostTests.m
//  Woot
//
//  Created by Aral Balkan on 15/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import "PostTests.h"
#import "Post.h"

//
// Re-implemented here to test the private properties
// (as I don't want to change my actual code just to test it.)
//
#import "GloballyUniqueID.h"
#import "Row.h"
@interface Post ()
@property (nonatomic, assign) NSUInteger localClockForRows;
@property (nonatomic, strong) Row *firstRow;
@property (nonatomic, strong) Row *lastRow;
@property (nonatomic, strong) NSString *siteIDString;
-(GloballyUniqueID *)nextRowID;
-(GloballyUniqueID *)rowIDWithLocalClock:(NSUInteger)localClock;
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

-(void)testFragmentIDOrder
{
    NSString *firstRowIDString = self.post.firstRow.selfID.stringValue;
    NSString *lastRowIDString = self.post.lastRow.selfID.stringValue;
    
    NSLog(@"First row ID: %@", firstRowIDString);
    NSLog(@"Last row ID: %@", lastRowIDString);
    
    STAssertEqualObjects(firstRowIDString, @"0-0", @"First row ID string should always be '0-0'.");
    STAssertEqualObjects(lastRowIDString, @"0-1", @"Last row ID string should always be '0-1'");
    
    GloballyUniqueID *id1 = [self.post nextRowID];
    GloballyUniqueID *id2 = [self.post nextRowID];
    
    STAssertTrue(id1.localClock < id2.localClock, @"Local clock of successive fragment IDs should be in ascending order.");
}

@end
