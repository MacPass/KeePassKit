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
#import "KPKEntry.h"
#import "KPKAutotype.h"
#import "KPKErrors.h"

@interface KPKWindowAssociation () {
  BOOL _regularExpressionIsValid;
}

@property (nonatomic, retain) NSRegularExpression *windowTitleRegularExpression;

@end

@implementation KPKWindowAssociation

+ (BOOL)supportsSecureCoding {
  return YES;
}

#pragma mark -
#pragma mark Lifecylce

- (id)initWithWindow:(NSString *)window keystrokeSequence:(NSString *)strokes {
  self = [super init];
  if(self) {
    _windowTitle = [window copy];
    _keystrokeSequence = [strokes copy];
    _regularExpressionIsValid = NO;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self && [aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    _windowTitle = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"windowTitle"];
    _keystrokeSequence = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"keystrokeSequence"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    [aCoder encodeObject:self.windowTitle forKey:@"windowTitle"];
    [aCoder encodeObject:self.keystrokeSequence forKey:@"keystrokeSequence"];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  return [[KPKWindowAssociation alloc] initWithWindow:self.windowTitle keystrokeSequence:self.keystrokeSequence];
}

#pragma mark -
#pragma mark Validation

- (BOOL)validateWindowTitle:(inout __autoreleasing id *)ioValue error:(out NSError *__autoreleasing *)outError {
  if(![*ioValue isKindOfClass:[NSString class]]) {
    KPKCreateError(outError, KPKErrorWindowTitleFormatValidationFailed, @"ERROR_WINDOW_TITLE_VALIDATION_FAILED", "");
    return NO;
  }
  return YES;
}

#pragma mark -
#pragma mark Properties
- (void)setWindowTitle:(NSString *)windowTitle {
  if(![self.windowTitle isEqualToString:windowTitle]) {
    [self.autotype.entry.undoManager registerUndoWithTarget:self selector:@selector(setWindowTitle:) object:self.windowTitle];
    _windowTitle = [windowTitle copy];
    _regularExpressionIsValid = NO;
  }
}

- (void)setKeystrokeSequence:(NSString *)keystrokeSequence {
  if(![self.keystrokeSequence isEqualToString:keystrokeSequence]) {
    [self.autotype.entry.undoManager registerUndoWithTarget:self selector:@selector(setKeystrokeSequence:) object:self.keystrokeSequence];
    _keystrokeSequence = [keystrokeSequence copy];
  }
}

- (BOOL)matchesWindowTitle:(NSString *)windowTitle {
  if(NSOrderedSame == [self.windowTitle caseInsensitiveCompare:windowTitle]) { return YES; }
  /* Only update the cached expression, if we need to */
  if(!_regularExpressionIsValid) {
    NSString *pattern;
    if([self.windowTitle hasPrefix:@"//"] && [self.windowTitle hasSuffix:@"//"]) {
      pattern = [self.windowTitle substringWithRange:NSMakeRange(2, [self.windowTitle length] - 4)];
    }
    else {
      pattern = [self.windowTitle stringByReplacingOccurrencesOfString:@"*" withString:@".*" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [self.windowTitle length])];
    }
    NSError *error;
    self.windowTitleRegularExpression = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if(!self.windowTitleRegularExpression) {
      NSLog(@"Error while trying to evaluate regular expression %@: %@", pattern, [error localizedDescription]);
      return NO;
    }
    _regularExpressionIsValid = YES;
  }
  NSUInteger matches = [self.windowTitleRegularExpression numberOfMatchesInString:windowTitle options:0 range:NSMakeRange(0, [windowTitle length])];
  return (matches == 1);
}

@end
