//
//  KPKMetaData.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
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

#import "KPKMetaData.h"
#import "KPKXmlFormat.h"
#import "KPKIcon.h"
#import "KPKTree.h"

#import "NSUUID+KeePassKit.h"

@interface KPKMetaData () {
  NSMutableDictionary *_customIconCache;
  NSMutableArray *_customIcons;
}


@end

@implementation KPKMetaData

- (id)init {
  self = [super init];
  if(self){
    _customData = [[NSMutableArray alloc] init];
    _customIcons = [[NSMutableArray alloc] init];
    _customIconCache = [[NSMutableDictionary alloc] init];
    _rounds = 6000;
    _compressionAlgorithm = KPKCompressionGzip;
    _protectNotes = NO;
    _protectPassword = YES;
    _protectTitle = NO;
    _protectUrl = NO;
    _protectUserName = NO;
    _generator = [@"MacPass" copy];
    _databaseName = [NSLocalizedString(@"DATABASE", "") copy];
    _databaseNameChanged = [NSDate date];
    _databaseDescription = [@"" copy];
    _databaseDescriptionChanged = [NSDate date];
    _defaultUserName = [@"" copy];
    _defaultUserNameChanged = [NSDate date];
    _entryTemplatesGroupChanged = [NSDate date];
    _entryTemplatesGroup = [NSUUID nullUUID];
    _recycleBinChanged = [NSDate date];
    _recycleBinUuid = [NSUUID nullUUID];
    _lastSelectedGroup = [NSUUID nullUUID];
    _lastTopVisibleGroup = [NSUUID nullUUID];
    _historyMaxItems = 10;
    _historyMaxSize = 6 * 1024 * 1024; // 6 MB
    _maintenanceHistoryDays = 365;
  }
  return self;
}

#pragma mark -
#pragma mark Properties
- (NSArray *)customIcons {
  return [_customIcons copy];
}

- (BOOL)isHistoryEnabled {
  return (self.historyMaxItems != -1);
}

- (void)setColor:(NSColor *)color {
  if(![_color isEqual:color]) {
    /*
     The color for databases does not support a alpha componentet
     thus we just stripp it
     */
    _color = [[color colorWithAlphaComponent:1.0] copy];
  }
}

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
  if(![_recycleBinUuid isEqual:recycleBinUuid]) {
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
  [[self.tree.undoManager prepareWithInvocationTarget:self] removeCustomIcon:icon];
  [self insertObject:icon inCustomIconsAtIndex:index];
}

- (void)removeCustomIcon:(KPKIcon *)icon {
  NSUInteger index = [_customIcons indexOfObject:icon];
  if(index != NSNotFound) {
    [[self.tree.undoManager prepareWithInvocationTarget:self] addCustomIcon:icon atIndex:index];
    [self removeObjectFromCustomIconsAtIndex:index];
  }
}

- (KPKIcon *)findIcon:(NSUUID *)uuid {
  return _customIconCache[uuid];
}

#pragma mark KVO

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  NSSet *keyPathSet = [super keyPathsForValuesAffectingValueForKey:key];
  if([key isEqualToString:@"isHistoryEnabled"]) {
    keyPathSet = [keyPathSet setByAddingObject:@"historyMaxItems"];
  }
  return keyPathSet;
}

- (NSUInteger)countOfCustomIcons {
  return [_customIcons count];
}

- (void)insertObject:(KPKIcon *)icon inCustomIconsAtIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  [_customIcons insertObject:icon atIndex:index];
  _customIconCache[icon.uuid] = icon;
}

- (void)removeObjectFromCustomIconsAtIndex:(NSUInteger)index {
  index = MIN([_customIcons count], index);
  KPKIcon *icon = _customIcons[index];
  [_customIcons removeObjectAtIndex:index];
  if(icon) {
    [_customIconCache removeObjectForKey:icon.uuid];
  }
}

@end
