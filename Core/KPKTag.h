//
//  KPKTag.h
//  MacPass
//
//  Created by Michael Starke on 14/03/14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;

@interface KPKTag : NSObject

@property (copy, readonly) NSString *name;

+ (instancetype)tagWithName:(NSString *)name;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)name;

@end
