//
//  KPKMetaData.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKMetaData.h"
#import "KPKIcon.h"

@implementation KPKMetaData

- (id)init {
  self = [super init];
  if(self){
    _customData = [[NSMutableArray alloc] init];
    _customIcons = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addCustomIcon:(KPKIcon *)icon {
  [self addCustomIcon:icon atIndex:[_customIcons count]];
}

- (void)addCustomIcon:(KPKIcon *)icon atIndex:(NSUInteger)index {
  /* Use undomanager ? */
  index = MIN([_customIcons count], index);
  [[self.undoManager prepareWithInvocationTarget:self] removeCustomIcon:icon];
  [self insertObject:icon inCustomIconsAtIndex:index];
}

- (void)removeCustomIcon:(KPKIcon *)icon {
  NSUInteger index = [_customIcons indexOfObject:icon];
  if(index != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:self] addCustomIcon:icon atIndex:index];
    [self removeObjectFromCustomIconsAtIndex:index];
  }
}

#pragma mark KVO

- (NSUInteger)countOfCustomIcons {
  return [_customIcons count];
}

- (void)insertObject:(KPKIcon *)icon inCustomIconsAtIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  [_customIcons insertObject:icon atIndex:index];
}

- (void)removeObjectFromCustomIconsAtIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  [_customIcons removeObjectAtIndex:index];
}

@end
