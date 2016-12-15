//
//  KPKMetaData_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 17/02/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKMetaData.h"
#import "KPKExtendedModificationRecording.h"

@class KPKBinary;
@class KPKIcon;

@interface KPKMetaData () <KPKExtendedModificationRecording>

@property(nonatomic, strong) NSMutableArray<KPKBinary *> *mutableCustomData;
@property(nonatomic, strong) NSMutableArray<KPKIcon *> *mutableCustomIcons;
@property(nonatomic, strong) NSMutableArray<KPKBinary *> *mutableUnknownMetaEntryData;
@property(nonatomic, strong) NSMutableDictionary *mutableCustomPublicData;

@end
