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

@interface KPKMetaData () <KPKExtendedModificationRecording>

@property(nonatomic, strong) NSMutableArray<KPKIcon *> *mutableCustomIcons;
@property(nonatomic, strong) NSMutableArray<KPKBinary *> *mutableUnknownMetaEntryData;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableCustomData;
@property(nonatomic, strong) NSMutableDictionary<NSString *, id> *mutableCustomPublicData;
@property(weak) KPKTree *tree;

- (void)_mergeWithMetaDataFromTree:(KPKTree *)tree mode:(KPKSynchronizationMode)mode;

@end
