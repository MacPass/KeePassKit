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

+ (instancetype)autotypeFromNotes:(NSString *)notes {
  /*
   TODO
   
   Notes contain Autotype information.
   Parse notes and extract any exisisting
   autotype info
   
   Autotype on KeePass1 Files works with different values,
   need to be converted!
   
   Auto-Type: {USERNAME}{TAB}{PASSWORD}{ENTER}
   Auto-Type-Window: Some Dialog - *
   Auto-Type-1: {USERNAME}{ENTER}
   Auto-Type-Window-1: * - Editor
   Auto-Type-Window-1: * - Notepad
   Auto-Type-Window-1: * - WordPad
   Auto-Type-2: {PASSWORD}{ENTER}
   Auto-Type-Window-2: Some Web Page - *
   
   See http://keepass.info/help/base/autotype.html for references!
   */
  NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:@"auto-type(-window){0,1}(-[0-9]*){0,1}:\\ *(.*)" options:NSRegularExpressionCaseInsensitive error:nil];
  __block KPKAutotype *autotype = [[KPKAutotype alloc] init];
  for(NSString *line in [notes componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
    [regExp enumerateMatchesInString:line options:0 range:NSMakeRange(0, line.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
      @autoreleasepool {
        
        NSRange windowRange = [result rangeAtIndex:1];
        NSRange numberRange = [result rangeAtIndex:2];
        NSRange titleOrCommandRange = [result rangeAtIndex:3];

        NSInteger currentIndex = 0;
        BOOL isAssociation = (windowRange.length != 0);
        BOOL hasTitleOrCommand = (titleOrCommandRange.length != 0);
        BOOL hasNumber = (numberRange.length != 0);
        
        /* Empty keystrokes or titles aren't allowed */
        if(!hasTitleOrCommand) {
          NSLog(@"Encountered emptry %@. Aborting!", isAssociation ? @"window title" : @"keystroke sequence");
          *stop = YES;
        }
        
        /* Associations need a autotype sequence, otherwise there's something missing */
        if(isAssociation) {
          NSString *windowTitle = [line substringWithRange:titleOrCommandRange];
          if(autotype.hasDefaultKeystrokeSequence) {
            NSLog(@"Encounterd window association %@ but no Autotype sequence was specified. Aborting!", windowTitle);
            *stop = YES;
          }
          else {
          
          }
        }
        
        if(hasNumber) {
          NSScanner *numberScanner = [[NSScanner alloc] initWithString:[line substringWithRange:numberRange]];
          NSInteger index = 0;
          if([numberScanner scanInteger:&index]) {
            index = labs(index);
            if(currentIndex + 1 == index) {
              currentIndex++;
            }
            else {
              NSLog(@"Encountered Autotype index %ld but expected %ld. Aborting!", index, currentIndex + 1 );
              *stop = YES;
            }
          }
        }
        
        
        
        
        if(*stop) {
          autotype = nil;
        }
      }
    }];
  }
  return autotype;
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
    _defaultKeystrokeSequence = [[aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(defaultKeystrokeSequence))] copy];
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