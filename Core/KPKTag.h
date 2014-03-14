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

@property (weak) KPKTree *tree;
@property (copy) NSString *name;
@property (nonatomic, assign, readonly) NSArray *entries;
@property (nonatomic, assign, readonly) NSArray *groups;

- (instancetype)initWithName:(NSString *)name;

@end
