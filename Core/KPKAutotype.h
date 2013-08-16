//
//  KPKAutotype.h
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKUndoing.h"

@class KPKEntry;
@class KPKWindowAssociation;

@interface KPKAutotype : NSObject <NSCopying, NSCoding>

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) BOOL obfuscateDataTransfer;
@property (nonatomic, copy) NSString *defaultSequence;
@property (nonatomic, strong, readonly) NSArray *associations;

@property (weak) KPKEntry *entry;

- (void)addAssociation:(KPKWindowAssociation *)association;
- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index;
- (void)removeAssociation:(KPKWindowAssociation *)association;

@end
