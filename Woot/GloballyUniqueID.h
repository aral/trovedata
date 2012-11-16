//
//  This is a unique ID in the form of a tuple: (SiteID, LogicalClock)
//
//  IMPORTANT LIMITATION: Currently, this is globally unique *for a specific post*.
//  ===================== This may or may not be enough as the app progresses. We may
//                        end up needing different types of global IDs for different objects
//                        based on how they are used.
//
//  The SiteID is calculated as a hash of the User ID, Device ID, and App ID.
//  TODO: Make own class (?)
//
//  Based on the WOOT (WithOut Operational Transformations) algorithms as presented in
//  the papers Data Consistency for P2P Collaborative Editing and Undo in Peer-to-peer Semantic Wikis
//  by Gérald Oster (osterg@inf.ethz.ch) at Institute for Information Systems ETH Zurich and Pascal Urso
//  (urso@loria.fr), Pascal Molli (molli@loria.fr), and Abdessamad Imine (imine@@loria.fr),
//  Charbel Rahhal (Charbel.Rahal@loria.fr), Stéphane Weiss (weiss@loria.fr), and Hala Skaf-Molli
//  (skaf@loria.fr) at Université Henri Poincaré, Nancy 1, Loria.
//
//  Created by Aral Balkan on 14/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GloballyUniqueID : NSObject

@property (nonatomic, strong) NSString *siteID;
@property (nonatomic, assign) NSUInteger localClock;

+(id)idWithSiteIDString:(NSString *)siteID localClock:(NSUInteger)localClock;
+(id)idWithGloballyUniqueIDString:(NSString *)globallyUniqueIDString;

-(id)initWithSiteIDString:(NSString *)siteID localClock:(NSUInteger)localClock;
-(id)initWithGloballyUniqueIDString:(NSString *)globallyUniqueIDString;

-(NSString *)stringValue;

@end
