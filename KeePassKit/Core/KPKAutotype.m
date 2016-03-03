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
#import "KPKAutotype+Private.h"
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKTree.h"
#import "KPKWindowAssociation.h"
#import "KPKWindowAssociation+Private.h"

@interface KPKAutotype () {
  NSMutableArray *_associations;
}

@end

@implementation KPKAutotype

@synthesize entry = _entry;
@synthesize defaultKeystrokeSequence = _defaultKeystrokeSequence;

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSSet *)keyPathsForValuesAffectingHasDefaultKeystrokeSequence {
  return [NSSet setWithObject:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _isEnabled = YES;
    _obfuscateDataTransfer = NO;
    _associations = [[NSMutableArray alloc] initWithCapacity:2];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
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
  [aCoder encodeBool:_isEnabled forKey:NSStringFromSelector(@selector(isEnabled))];
  [aCoder encodeBool:_obfuscateDataTransfer forKey:NSStringFromSelector(@selector(obfuscateDataTransfer))];
  [aCoder encodeObject:_associations forKey:NSStringFromSelector(@selector(associations))];
  [aCoder encodeObject:_defaultKeystrokeSequence forKey:NSStringFromSelector(@selector(defaultKeystrokeSequence))];
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

- (BOOL)isEqual:(id)object {
  if(![object isKindOfClass:self.class]) {
    return NO;
  }
  return [self isEqualToAutotype:object];
}

- (BOOL)isEqualToAutotype:(KPKAutotype *)autotype {
  if(!autotype) {
    return NO;
  }
  if(self.isEnabled != autotype.isEnabled) {
    return NO;
  }
  if(self.obfuscateDataTransfer != autotype.obfuscateDataTransfer) {
    return NO;
  }
  if(self.hasDefaultKeystrokeSequence != autotype.hasDefaultKeystrokeSequence) {
    return NO;
  }
  if(!self.hasDefaultKeystrokeSequence && ![self.defaultKeystrokeSequence isEqualToString:autotype.defaultKeystrokeSequence]) {
    /* no default so the sequences need to match */
    return NO;
  }
  if(![self.associations isEqualToArray:autotype.associations]) {
    return NO;
  }
  return YES;
}

- (NSString *)defaultKeystrokeSequence {
  /* The default sequence is inherited, so just bubble up */
  if(self.hasDefaultKeystrokeSequence) {
    return self.entry.parent.defaultAutoTypeSequence;
  }
  return _defaultKeystrokeSequence;
}

- (void)setDefaultKeystrokeSequence:(NSString *)defaultSequence {
  _defaultKeystrokeSequence = defaultSequence.length  > 0 ? [defaultSequence copy] : nil;
}

- (NSArray *)associations {
  return [_associations copy];
}

- (void)addAssociation:(KPKWindowAssociation *)association {
  [self addAssociation:association atIndex:_associations.count];
}

- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index {
  association.autotype = self;
  [self insertObject:association inAssociationsAtIndex:index];
}

- (void)removeAssociation:(KPKWindowAssociation *)association {
  NSUInteger index = [_associations indexOfObject:association];
  if(index != NSNotFound) {
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
  return ! _defaultKeystrokeSequence.length > 0;
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