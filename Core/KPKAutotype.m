//
//  KPKAutotype.m
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "KPKAutotype.h"
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKTree.h"
#import "KPKWindowAssociation.h"

@interface KPKAutotype () {
  NSMutableArray *_associations;
  NSString *_defaultKeystrokeSequence;
}

@end

@implementation KPKAutotype

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSSet *)keyPathsForValuesAffectingHasDefaultKeystrokeSequence {
  return [NSSet setWithObject:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
}

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
    _isEnabled = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isEnabled))];
    _obfuscateDataTransfer = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(obfuscateDataTransfer))];
    _defaultKeystrokeSequence = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
    _associations = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(associations))];
    for(KPKWindowAssociation *association in _associations) {
      association.autotype = self;
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeBool:self.isEnabled forKey:NSStringFromSelector(@selector(isEnabled))];
  [aCoder encodeBool:self.obfuscateDataTransfer forKey:NSStringFromSelector(@selector(obfuscateDataTransfer))];
  [aCoder encodeObject:_associations forKey:NSStringFromSelector(@selector(associations))];
  [aCoder encodeObject:self.defaultKeystrokeSequence forKey:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
}

- (id)copyWithZone:(NSZone *)zone {
  KPKAutotype *copy = [[KPKAutotype alloc] init];
  copy.isEnabled = _isEnabled;
  copy.obfuscateDataTransfer = _obfuscateDataTransfer;
  copy->_associations = [[NSMutableArray alloc] initWithArray:self.associations copyItems:YES];
  copy.defaultKeystrokeSequence = _defaultKeystrokeSequence;
  copy.entry = _entry;
  for(KPKWindowAssociation *association in copy->_associations) {
    association.autotype = copy;
  }
  return copy;
}

- (NSString *)defaultKeystrokeSequence {
  /* The default sequence is inherited, so just bubble up */
  if([self hasDefaultKeystrokeSequence]) {
    return self.entry.parent.defaultAutoTypeSequence;
  }
  return _defaultKeystrokeSequence;
}

- (void)setDefaultKeystrokeSequence:(NSString *)defaultSequence {
  if(![self.defaultKeystrokeSequence isEqualToString:defaultSequence]) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] setDefaultKeystrokeSequence:self.defaultKeystrokeSequence];
  }
  _defaultKeystrokeSequence = [defaultSequence length]  > 0 ? [defaultSequence copy] : nil;
}

- (NSArray *)associations {
  return [_associations copy];
}

- (void)setIsEnabled:(BOOL)isEnabled {
  if(self.isEnabled != isEnabled) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] setIsEnabled:self.isEnabled];
    _isEnabled = isEnabled;
  }
}

- (void)setObfuscateDataTransfer:(BOOL)obfuscateDataTransfer {
  if(self.obfuscateDataTransfer != obfuscateDataTransfer) {
    [[self.entry.undoManager prepareWithInvocationTarget:self] setObfuscateDataTransfer:self.obfuscateDataTransfer];
    _obfuscateDataTransfer = obfuscateDataTransfer;
  }
}

- (void)addAssociation:(KPKWindowAssociation *)association {
  [self addAssociation:association atIndex:[_associations count]];
}

- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index {
  [self.entry.tree.undoManager registerUndoWithTarget:self selector:@selector(removeAssociation:) object:association];
  association.autotype = self;
  [self insertObject:association inAssociationsAtIndex:index];
}

- (void)removeAssociation:(KPKWindowAssociation *)association {
  NSUInteger index = [_associations indexOfObject:association];
  if(index != NSNotFound) {
    [[self.entry.tree.undoManager prepareWithInvocationTarget:self] addAssociation:association atIndex:index];
    association.autotype = nil;
    [self removeObjectFromAssociationsAtIndex:index];
  }
}

- (KPKWindowAssociation *)windowAssociationMatchingWindowTitle:(NSString *)windowTitle {
  for(KPKWindowAssociation *association in self.associations) {
    if([association matchesWindowTitle:windowTitle]) {
      return association;
    }
  }
  return nil;
}

- (BOOL)hasDefaultKeystrokeSequence {
  return ! [_defaultKeystrokeSequence length] > 0;
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
