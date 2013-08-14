//
//  KPKWindowAssociation.m
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKWindowAssociation.h"
#import "KPKEntry.h"

@implementation KPKWindowAssociation

- (void)setWindowTitle:(NSString *)windowTitle {
  if(![self.windowTitle isEqualToString:windowTitle]) {
    [self.undoManager registerUndoWithTarget:self selector:@selector(setWindowTitle:) object:self.windowTitle];
    _windowTitle = [windowTitle copy];
  }
}

- (void)setKeystrokeSequence:(NSString *)keystrokeSequence {
  if(![self.keystrokeSequence isEqualToString:keystrokeSequence]) {
    [self.undoManager registerUndoWithTarget:self selector:@selector(setKeystrokeSequence:) object:self.keystrokeSequence];
    self.keystrokeSequence = [keystrokeSequence copy];
  }
}

- (NSString *)evaluatedKeystrokeSequenceForEntry:(KPKEntry *)enty {
  // parse for placeholder
  return nil;
}

@end
