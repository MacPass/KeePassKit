//
//  KPKWindowAssociation.m
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKWindowAssociation.h"
#import "KPKEntry.h"
#import "KPKAutotype.h"

@interface KPKWindowAssociation () {
  BOOL _regularExpressionIsValid;
}

@property (nonatomic, retain) NSRegularExpression *windowTitleRegularExpression;

@end

@implementation KPKWindowAssociation

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
    _windowTitle = [aDecoder decodeObjectForKey:@"windowTitle"];
    _keystrokeSequence = [aDecoder decodeObjectForKey:@"keystrokeSequence"];
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
      pattern = [self.windowTitle stringByReplacingOccurrencesOfString:@"*" withString:@"*." options:NSCaseInsensitiveSearch range:NSMakeRange(0, [self.windowTitle length])];
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
