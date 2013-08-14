//
//  KPKAutotype.h
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKUndoing.h"

@class KPKWindowAssociation;

@interface KPKAutotype : NSObject <KPKUndoing>

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) BOOL obfuscateDataTransfer;
@property (nonatomic, copy) NSString *defaultSequence;
@property (nonatomic, strong, readonly) NSArray *associations;

- (void)addAssociation:(KPKWindowAssociation *)association;
- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index;
- (void)removeAssociation:(KPKWindowAssociation *)associtaions;

@property(nonatomic, weak) NSUndoManager *undoManager;

@end
