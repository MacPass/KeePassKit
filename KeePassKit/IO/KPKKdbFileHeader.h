//
//  KPKKDBFileHeader.h
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileHeader.h"

@interface KPKKdbFileHeader : KPKFileHeader

@property (nonatomic, readonly, copy) NSData *headerData;
@property (nonatomic, readonly, copy) NSData *headerHash;
@property (nonatomic, readonly) NSUInteger numberOfEntries;
@property (nonatomic, readonly) NSUInteger numberOfGroups;

@end
