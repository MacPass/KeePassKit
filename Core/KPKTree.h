//
//  KPLTree.h
//  MacPass
//
//  Created by Michael Starke on 11.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKDatabaseVersion.h"

@class KPLGroup;
@class KPLEntry;
@class KPLPassword;

@interface KPKTree : NSObject

@property (nonatomic, strong) KPLGroup *root;
@property (nonatomic, readonly) KPLDatabaseVersion minimumVersion;

- (id)initWithData:(NSData *)data password:(KPLPassword *)password;

- (NSData *)serializeWithPassword:(KPLPassword *)password error:(NSError *)error;

- (KPLGroup *)createGroup:(KPLGroup *)parent;
- (KPLEntry *)createEntry:(KPLGroup *)parent;

@end
