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

@implementation KPKWindowAssociation

- (id)initWithWindow:(NSString *)window keystrokeSequence:(NSString *)strokes {
  self = [super init];
  if(self) {
    _windowTitle = [window copy];
    _keystrokeSequence = [strokes copy];
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
  }
}

- (void)setKeystrokeSequence:(NSString *)keystrokeSequence {
  if(![self.keystrokeSequence isEqualToString:keystrokeSequence]) {
    [self.autotype.entry.undoManager registerUndoWithTarget:self selector:@selector(setKeystrokeSequence:) object:self.keystrokeSequence];
    _keystrokeSequence = [keystrokeSequence copy];
  }
}

- (NSString *)evaluatedKeystrokeSequenceForEntry:(KPKEntry *)enty {
  NSAssert(NO, @"Not implemented!");
  return nil;
}

@end
