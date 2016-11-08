//
//  KPKWindowAssociation.m
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

#import "KPKWindowAssociation.h"
#import "KPKWindowAssociation_Private.h"
#import "KPKEntry.h"
#import "KPKAutotype.h"
#import "KPKErrors.h"

@interface KPKWindowAssociation () {
  BOOL _regularExpressionIsValid;
  NSString *_keystrokeSequence;
}

@property (nonatomic, retain) NSRegularExpression *windowTitleRegularExpression;

@end

@implementation KPKWindowAssociation

@synthesize autotype = _autotype;

+ (BOOL)supportsSecureCoding {
  return YES;
}

#pragma mark -
#pragma mark Lifecylce

- (instancetype)init {
  self = [self initWithWindowTitle:nil keystrokeSequence:nil];
  return self;
}

- (instancetype)initWithWindowTitle:(NSString *)windowTitle keystrokeSequence:(NSString *)strokes {
  self = [super init];
  if(self) {
    _windowTitle = [windowTitle copy];
    _keystrokeSequence = [strokes copy];
    _regularExpressionIsValid = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self && [aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    _windowTitle = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(windowTitle))];
    _keystrokeSequence = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(keystrokeSequence))];
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if(![object isKindOfClass:self.class]) {
    return NO;
  }
  return [self isEqualToWindowAssociation:object];
}

- (BOOL)isEqualToWindowAssociation:(KPKWindowAssociation *)other {
  if(!other) {
    return NO;
  }
  if(self.hasDefaultKeystrokeSequence != other.hasDefaultKeystrokeSequence) {
    return NO;
  }
  if(self.hasDefaultKeystrokeSequence && ![self.keystrokeSequence isEqualToString:other.keystrokeSequence]) {
    return NO;
  }
  if(![self.windowTitle isEqualToString:other.windowTitle]) {
    return NO;
  }
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    [aCoder encodeObject:_windowTitle forKey:NSStringFromSelector(@selector(windowTitle))];
    [aCoder encodeObject:_keystrokeSequence forKey:NSStringFromSelector(@selector(keystrokeSequence))];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  return [[KPKWindowAssociation alloc] initWithWindowTitle:self.windowTitle keystrokeSequence:_keystrokeSequence];
}

#pragma mark -
#pragma mark Validation

- (BOOL)validateWindowTitle:(inout __autoreleasing id *)ioValue error:(out NSError *__autoreleasing *)outError {
  if(![*ioValue isKindOfClass:[NSString class]]) {
    KPKCreateError(outError, KPKErrorWindowTitleFormatValidationFailed);
    return NO;
  }
  return YES;
}

#pragma mark -
#pragma mark Properties
- (NSString *)keystrokeSequence {
  if(_keystrokeSequence) {
    return _keystrokeSequence;
  }
  return self.autotype.defaultKeystrokeSequence;
}

- (void)setWindowTitle:(NSString *)windowTitle {
  if(![self.windowTitle isEqualToString:windowTitle]) {
    [self.autotype.entry.undoManager registerUndoWithTarget:self selector:@selector(setWindowTitle:) object:self.windowTitle];
    [self.autotype.entry touchModified];
    _windowTitle = [windowTitle copy];
    _regularExpressionIsValid = NO;
  }
}

- (void)setKeystrokeSequence:(NSString *)keystrokeSequence {
  if(![self.keystrokeSequence isEqualToString:keystrokeSequence]) {
    [self.autotype.entry.undoManager registerUndoWithTarget:self selector:@selector(setKeystrokeSequence:) object:self.keystrokeSequence];
    [self.autotype.entry touchModified];
    _keystrokeSequence = [keystrokeSequence copy];
  }
}

- (BOOL)hasDefaultKeystrokeSequence {
  return !(_keystrokeSequence.length > 0);
}

- (BOOL)matchesWindowTitle:(NSString *)windowTitle {
  if(NSOrderedSame == [self.windowTitle caseInsensitiveCompare:windowTitle]) {
    return YES;
  }
  /* Only update the cached expression, if we need to */
  if(!_regularExpressionIsValid) {
    NSString *pattern;
    if([self.windowTitle hasPrefix:@"//"] && [self.windowTitle hasSuffix:@"//"]) {
      pattern = [self.windowTitle substringWithRange:NSMakeRange(2, self.windowTitle.length - 4)];
    }
    else {
      pattern = [self.windowTitle stringByReplacingOccurrencesOfString:@"*" withString:@".*" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.windowTitle.length)];
    }
    NSError *error;
    self.windowTitleRegularExpression = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if(!self.windowTitleRegularExpression) {
      NSLog(@"Error while trying to evaluate regular expression %@: %@", pattern, error.localizedDescription);
      return NO;
    }
    _regularExpressionIsValid = YES;
  }
  NSUInteger matches = [self.windowTitleRegularExpression numberOfMatchesInString:windowTitle options:0 range:NSMakeRange(0, windowTitle.length)];
  return (matches == 1);
}

@end
