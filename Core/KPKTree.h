//
//  KPKTree.h
//  KeePassKit
//
//  Created by Michael Starke on 11.07.13.
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

#import <Foundation/Foundation.h>
#import "KPKVersion.h"
#import "KPKNode.h"

@class KPKGroup;
@class KPKEntry;
@class KPKPassword;

@interface KPKTree : KPKNode

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
@property(nonatomic, copy) NSString *color;
@property(nonatomic, strong) NSDate *masterKeyChanged;
@property(nonatomic, assign) NSInteger masterKeyChangeRec;
@property(nonatomic, assign) NSInteger masterKeyChangeForce;
@property(nonatomic, assign) BOOL protectTitle;
@property(nonatomic, assign) BOOL protectUserName;
@property(nonatomic, assign) BOOL protectPassword;
@property(nonatomic, assign) BOOL protectUrl;
@property(nonatomic, assign) BOOL protectNotes;
@property(nonatomic, strong, readonly) NSMutableArray *customIcons;
@property(nonatomic, assign) BOOL recycleBinEnabled;
@property(nonatomic, strong) NSUUID *recycleBinUuid;
@property(nonatomic, strong) NSDate *recycleBinChanged;
@property(nonatomic, strong) NSUUID *entryTemplatesGroup;
@property(nonatomic, strong) NSDate *entryTemplatesGroupChanged;
@property(nonatomic, assign) NSInteger historyMaxItems;
@property(nonatomic, assign) NSInteger historyMaxSize;
@property(nonatomic, strong) NSUUID *lastSelectedGroup;
@property(nonatomic, strong) NSUUID *lastTopVisibleGroup;
@property(nonatomic, strong, readonly) NSMutableArray *customData;


@property (nonatomic, assign) KPKGroup *root;
/**
 Acces to the root group via the groups property
 to offer a bindiable interface for a tree
 */
@property (nonatomic, readonly) NSArray *groups;
@property (nonatomic, readonly) NSArray *allGroups;
@property (nonatomic, readonly) NSArray *allEntries;

- (id)initWithData:(NSData *)data password:(KPKPassword *)password;

- (KPKGroup *)createGroup:(KPKGroup *)parent;
- (KPKEntry *)createEntry:(KPKGroup *)parent;

@end
