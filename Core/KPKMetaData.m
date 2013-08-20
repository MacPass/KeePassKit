//
//  KPKMetaData.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKMetaData.h"
#import "KPKXmlFormat.h"
#import "KPKIcon.h"

#import "NSUUID+KeePassKit.h"

@implementation KPKMetaData

- (id)init {
  self = [super init];
  if(self){
    _customData = [[NSMutableArray alloc] init];
    _customIcons = [[NSMutableArray alloc] init];
    _rounds = 6000;
    _compressionAlgorithm = KPKCompressionGzip;
    _protectNotes = NO;
    _protectPassword = YES;
    _protectTitle = NO;
    _protectUrl = NO;
    _protectUserName = NO;
    _generator = [@"MacPass" copy];
    _databaseNameChanged = [NSDate date];
    _databaseDescriptionChanged = [NSDate date];
    _defaultUserNameChanged = [NSDate date];
    _entryTemplatesGroupChanged = [NSDate date];
    _entryTemplatesGroup = [NSUUID nullUUID];
    _recycleBinChanged = [NSDate date];
    _recycleBinUuid = [NSUUID nullUUID];
    _lastSelectedGroup = [NSUUID nullUUID];
    _lastTopVisibleGroup = [NSUUID nullUUID];
  }
  return self;
}

#pragma mark -
#pragma mark Custom Setter
- (void)setDatabaseName:(NSString *)databaseName {
  if(![_databaseName isEqualToString:databaseName]) {
    _databaseName = [databaseName copy];
    if(_updateTiming) {
      self.databaseNameChanged = [NSDate date];
    }
  }
}

- (void)setDatabaseDescription:(NSString *)databaseDescription {
  if(![_databaseDescription isEqualToString:databaseDescription]) {
    _databaseDescription = [databaseDescription copy];
    if(_updateTiming) {
      self.databaseNameChanged = [NSDate date];
    }
  }
}

- (void)setDefaultUserName:(NSString *)defaultUserName {
  if(![_defaultUserName isEqualToString:defaultUserName]) {
    _defaultUserName = [defaultUserName copy];
    if(_updateTiming) {
      self.defaultUserNameChanged = [NSDate date];
    }
  }
}

- (void)setEntryTemplatesGroup:(NSUUID *)entryTemplatesGroup {
  if(![_entryTemplatesGroup isEqual:entryTemplatesGroup]) {
    _entryTemplatesGroup = entryTemplatesGroup;
    if(_updateTiming) {
      self.entryTemplatesGroupChanged = [NSDate date];
    }
  }
}

- (void)setRecycleBinUuid:(NSUUID *)recycleBinUuid {
  if([_recycleBinUuid isEqual:recycleBinUuid]) {
    _recycleBinUuid = recycleBinUuid;
    if(_updateTiming) {
      self.recycleBinChanged = [NSDate date];
    }
  }
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
