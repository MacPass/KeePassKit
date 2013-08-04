//
//  KPKMetaData.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKUndoing.h"
#import "KPKTimerecording.h"
#import "KPKIcon.h"

@interface KPKMetaData : NSObject <KPKUndoing, KPKTimerecording>

@property(nonatomic, assign) uint64_t rounds;
@property(nonatomic, assign) uint32_t compressionAlgorithm;

@property(nonatomic, copy) NSString *generator;

@property(nonatomic, copy) NSString *databaseName;
@property(nonatomic, strong) NSDate *databaseNameChanged;
@property(nonatomic, copy) NSString *databaseDescription;
@property(nonatomic, strong) NSDate *databaseDescriptionChanged;

@property(nonatomic, copy) NSString *defaultUserName;
@property(nonatomic, strong) NSDate *defaultUserNameChanged;
@property(nonatomic, assign) NSInteger maintenanceHistoryDays;

/* Hexstring - #AA77FF */
@property(nonatomic, copy) NSString *color;

@property(nonatomic, strong) NSDate *masterKeyChanged;
@property(nonatomic, assign) NSInteger masterKeyChangeIsRequired;
@property(nonatomic, assign) NSInteger masterKeyChangeIsForced;

@property(nonatomic, assign) BOOL protectTitle;
@property(nonatomic, assign) BOOL protectUserName;
@property(nonatomic, assign) BOOL protectPassword;
@property(nonatomic, assign) BOOL protectUrl;
@property(nonatomic, assign) BOOL protectNotes;

@property(nonatomic, assign) BOOL recycleBinEnabled;
@property(nonatomic, strong) NSUUID *recycleBinUuid;
@property(nonatomic, strong) NSDate *recycleBinChanged;

@property(nonatomic, strong) NSUUID *entryTemplatesGroup;
@property(nonatomic, strong) NSDate *entryTemplatesGroupChanged;

@property(nonatomic, assign) NSInteger historyMaxItems;
@property(nonatomic, assign) NSInteger historyMaxSize; // Megabytes

@property(nonatomic, strong) NSUUID *lastSelectedGroup;
@property(nonatomic, strong) NSUUID *lastTopVisibleGroup;

@property(nonatomic, strong, readonly) NSMutableArray *customData;
@property(nonatomic, strong, readonly) NSMutableArray *customIcons;
@property(nonatomic, strong, readonly) NSMutableArray *unknownMetaEntries; // Compatibility for KDB files

@property(nonatomic, assign) BOOL updateTiming;
@property(nonatomic, weak) NSUndoManager *undoManager;

- (void)addCustomIcon:(KPKIcon *)icon;
- (void)addCustomIcon:(KPKIcon *)icon atIndex:(NSUInteger)index;
- (void)removeCustomIcon:(KPKIcon *)icon;


@end
