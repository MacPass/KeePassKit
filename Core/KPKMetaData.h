//
//  KPKMetaData.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKTimerecording.h"
#import "KPKIcon.h"

@class KPKTree;

@interface KPKMetaData : NSObject <KPKTimerecording>

@property (nonatomic, weak) KPKTree *tree;

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
@property(nonatomic, copy) NSColor *color;

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

@property(nonatomic, readonly) BOOL isHistoryEnabled;
@property(nonatomic, assign) NSInteger historyMaxItems;
@property(nonatomic, assign) NSInteger historyMaxSize; // Megabytes

@property(nonatomic, strong) NSUUID *lastSelectedGroup;
@property(nonatomic, strong) NSUUID *lastTopVisibleGroup;


@property(nonatomic, strong, readonly) NSMutableArray *customData;
/**
 *	Array of KPKIcon objects
 */
@property(nonatomic, strong, readonly) NSMutableArray *customIcons;
/**
 *	Array of KPKBinary objects - extracted from unknown meta entries. Notes is mapped to name, data to data
 */
@property(nonatomic, strong, readonly) NSMutableArray *unknownMetaEntryData; // Array of KPKBinaries Compatibility for KDB files

@property(nonatomic, assign) BOOL updateTiming;

- (void)addCustomIcon:(KPKIcon *)icon;
- (void)addCustomIcon:(KPKIcon *)icon atIndex:(NSUInteger)index;
- (void)removeCustomIcon:(KPKIcon *)icon;


@end
