//
//  KPKXmlElements.h
//  MacPass
//
//  Created by Michael Starke on 05/12/13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Nodes

extern NSString *const kKPKXmlKeePassFile;
extern NSString *const kKPKXmlRoot;
extern NSString *const kKPKXmlHeaderHash;
extern NSString *const kKPKXmlMeta;
extern NSString *const kKPKXmlGroup;
/* Meta */
extern NSString *const kKPKXmlGenerator;
extern NSString *const kKPKXmlDatabaseName;
extern NSString *const kKPKXmlDatabaseNameChanged;

extern NSString *const kKPKXmlDatabaseDescription;
extern NSString *const kKPKXmlDatabaseDescriptionChanged;
extern NSString *const kKPKXmlDefaultUserName;
extern NSString *const kKPKXmlDefaultUserNameChanged;
extern NSString *const kKPKXmlMaintenanceHistoryDays;
extern NSString *const kKPKXmlColor;
extern NSString *const kKPKXmlMasterKeyChanged;
extern NSString *const kKPKXmlMasterKeyChangeRec;
extern NSString *const kKPKXmlMasterKeyChangeForce;

extern NSString *const kKPKXmlMemoryProtection;
extern NSString *const kKPKXmlProtectTitle;
extern NSString *const kKPKXmlProtectUserName;
extern NSString *const kKPKXmlProtectPassword;
extern NSString *const kKPKXmlProtectURL;
extern NSString *const kKPKXmlProtectNotes;

extern NSString *const kKPKXmlRecycleBinEnabled;
extern NSString *const kKPKXmlRecycleBinUUID;
extern NSString *const kKPKXmlRecycleBinChanged;
extern NSString *const kKPKXmlEntryTemplatesGroup;
extern NSString *const kKPKXmlEntryTemplatesGroupChanged;
extern NSString *const kKPKXmlHistoryMaxItems;
extern NSString *const kKPKXmlHistoryMaxSize;
extern NSString *const kKPKXmlLastSelectedGroup;
extern NSString *const kKPKXmlLastTopVisibleGroup;

#pragma mark Attributes

extern NSString *const kKPKXmlProtected;
extern NSString *const kKPKXmlTrue;
extern NSString *const kKPKXmlFalse;