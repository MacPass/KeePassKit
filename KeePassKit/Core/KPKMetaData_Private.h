//
//  KPKMetaData_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 17/02/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKMetaData.h"
#import "KPKExtendedModificationRecording.h"
#import "KPKSynchronizationOptions.h"

@class KPKBinary;
@class KPKIcon;
@class KPKBinary;
@class KPKModifiedString;

@interface KPKMetaData () <KPKExtendedModificationRecording>

@property (nonatomic, copy) NSDate *databaseNameChanged;
@property (nonatomic, copy) NSDate *databaseDescriptionChanged;
@property (nonatomic, copy) NSDate *defaultUserNameChanged;
@property (nonatomic, copy) NSDate *trashChanged;
@property (nonatomic, copy) NSDate *entryTemplatesGroupChanged;
@property (copy) NSDate *settingsChanged;

@property(nonatomic, strong) NSMutableArray<KPKIcon *> *mutableCustomIcons;
@property(nonatomic, strong) NSMutableArray<KPKBinary *> *mutableUnknownMetaEntryData;
@property(nonatomic, strong) NSMutableDictionary<NSString *, KPKModifiedString *> *mutableCustomData;
@property(nonatomic, strong) NSMutableDictionary<NSString *, id> *mutableCustomPublicData;

@property(weak) KPKTree *tree;

- (void)_mergeWithMetaDataFromTree:(KPKTree *)tree mode:(KPKSynchronizationMode)mode;
- (void)_removeCustomIconAtIndex:(NSUInteger)index;

@end
