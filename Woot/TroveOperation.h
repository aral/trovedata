//
//  TroveOperation.h
//  Woot
//
//  Created by Aral Balkan on 16/11/2012.
//  Copyright (c) 2012 Aral Balkan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TroveOperation <NSObject>
@required
-(BOOL)doesSatisfyPrecondition;
-(void)execute;
@end
