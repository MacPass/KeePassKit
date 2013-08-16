//
//  KPKAutotype.m
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAutotype.h"
#import "KPKEntry.h"
#import "KPKWindowAssociation.h"

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

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self) {
    _isEnabled = [aDecoder decodeBoolForKey:@"isEnabled"];
    _obfuscateDataTransfer = [aDecoder decodeBoolForKey:@"obfuscateDataTransfer"];
    _associations = [aDecoder decodeObjectForKey:@"associations"];
    for(KPKWindowAssociation *association in _associations) {
      association.autotype = self;
    }
  }
  return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeBool:self.isEnabled forKey:@"isEnabled"];
  [aCoder encodeBool:self.obfuscateDataTransfer forKey:@"obfuscateDataTransfer"];
  [aCoder encodeObject:self.associations forKey:@"associations"];
}

- (id)copyWithZone:(NSZone *)zone {
  KPKAutotype *copy = [[KPKAutotype alloc] init];
  copy->_isEnabled = _isEnabled;
  copy->_obfuscateDataTransfer = _obfuscateDataTransfer;
  copy->_associations = [_associations copyWithZone:zone];
  copy->_entry = _entry;
  for(KPKWindowAssociation *association in copy->_associations) {
    association.autotype = copy;
  }
  return copy;
}


- (void)setIsEnabled:(BOOL)isEnabled {
  if(self.isEnabled != isEnabled) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] setIsEnabled:self.isEnabled];
    self.isEnabled = isEnabled;
  }
}

- (void)setObfuscateDataTransfer:(BOOL)obfuscateDataTransfer {
  if(self.obfuscateDataTransfer != obfuscateDataTransfer) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] setObfuscateDataTransfer:self.obfuscateDataTransfer];
    self.obfuscateDataTransfer = obfuscateDataTransfer;
  }
}

- (void)addAssociation:(KPKWindowAssociation *)association {
  [self addAssociation:association atIndex:[_associations count]];
}

- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index {
  [self.entry.undoManager registerUndoWithTarget:self selector:@selector(removeAssociation:) object:association];
  association.autotype = self;
  [self insertObject:association inAssociationsAtIndex:index];
}

- (void)removeAssociation:(KPKWindowAssociation *)association {
  NSUInteger index = [_associations indexOfObject:association];
  if(index != NSNotFound) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] addAssociation:association atIndex:index];
    association.autotype = nil;
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
