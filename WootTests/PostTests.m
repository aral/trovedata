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
#import "FragmentID.h"
@interface Post ()
@property (nonatomic, assign) NSUInteger localClock;
@property (nonatomic, strong) FragmentID *firstFragmentID;
@property (nonatomic, strong) FragmentID *lastFragmentID;
@property (nonatomic, strong) NSString *siteIDString;
-(FragmentID *)nextFragmentID;
-(FragmentID *)fragmentIDWithLocalClock:(NSUInteger)localClock;
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
    NSUInteger firstFragmentIDLocalClock = self.post.firstFragmentID.localClock;
    NSUInteger lastFragmentIDLocalClock = self.post.lastFragmentID.localClock;
    
    NSLog(@"First fragment ID local clock: %lu", firstFragmentIDLocalClock);
    NSLog(@"Last fragment ID local clock: %lu", lastFragmentIDLocalClock);
    
    STAssertEquals(firstFragmentIDLocalClock, (NSUInteger)0, @"Local clock of first fragment ID in the post should be zero.");
    STAssertEquals(lastFragmentIDLocalClock, NSUIntegerMax, @"Local clock of last fragment ID in the post should be %lu", NSUIntegerMax);
    STAssertTrue(firstFragmentIDLocalClock < lastFragmentIDLocalClock, @"Local clock of first fragment ID in the post should be less than the local clock of the last fragment ID in the post.");
    
    FragmentID *id1 = [self.post nextFragmentID];
    FragmentID *id2 = [self.post nextFragmentID];
    
    STAssertTrue(id1.localClock < id2.localClock, @"Local clock of successive fragment IDs should be in ascending order.");
}

@end
