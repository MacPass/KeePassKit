//
//  KPKAutotype.m
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAutotype.h"

@interface KPKAutotype () {
  NSMutableArray *_associations;
}

@end

@implementation KPKAutotype

- (id)init {
  self = [super init];
  if(self) {
    _isEnabled = YES;
    _obfuscateDataTransfer = NO;
    _associations = [[NSMutableArray alloc] initWithCapacity:2];
  }
  return self;
}

- (void)setIsEnabled:(BOOL)isEnabled {
  if(self.isEnabled != isEnabled) {
    [[self.undoManager prepareWithInvocationTarget:self] setIsEnabled:self.isEnabled];
    self.isEnabled = isEnabled;
  }
}

- (void)setObfuscateDataTransfer:(BOOL)obfuscateDataTransfer {
  if(self.obfuscateDataTransfer != obfuscateDataTransfer) {
    [[self.undoManager prepareWithInvocationTarget:self] setObfuscateDataTransfer:self.obfuscateDataTransfer];
    self.obfuscateDataTransfer = obfuscateDataTransfer;
  }
}

- (void)addAssociation:(KPKWindowAssociation *)association {
  [self addAssociation:association atIndex:[_associations count]];
}

- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index {
  [self.undoManager registerUndoWithTarget:self selector:@selector(removeAssociation:) object:association];
  [self insertObject:association inAssociationsAtIndex:index];
}

- (void)removeAssociation:(KPKWindowAssociation *)associtaions {
  NSUInteger index = [_associations indexOfObject:associtaions];
  if(index != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:self] addAssociation:associtaions atIndex:index];
    [self removeObjectFromAssociationsAtIndex:index];
  }
}

#pragma mark -
#pragma mark KVO Compliance

- (void)insertObject:(KPKWindowAssociation *)association inAssociationsAtIndex:(NSUInteger)index {
  index = MIN(index, [_associations count]);
  [_associations insertObject:association atIndex:index];
}

- (void)removeObjectFromAssociationsAtIndex:(NSUInteger)index {
  KPKWindowAssociation *association = _associations[index];
  if(association) {
    [_associations removeObjectAtIndex:index];
  }
}

@end
