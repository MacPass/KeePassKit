//
//  KPKXmlElements.h
//  MacPass
//
//  Created by Michael Starke on 05/12/13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Format
FOUNDATION_EXTERN NSString *const kKPKXmlKeePassFile;
FOUNDATION_EXTERN NSString *const kKPKXmlRoot;
FOUNDATION_EXTERN NSString *const kKPKXmlHeaderHash;
FOUNDATION_EXTERN NSString *const kKPKXmlMeta;
FOUNDATION_EXTERN NSString *const kKPKXmlGroup;

#pragma mark Metainformation
FOUNDATION_EXTERN NSString *const kKPKXmlGenerator;
FOUNDATION_EXTERN NSString *const kKPKXmlDatabaseName;
FOUNDATION_EXTERN NSString *const kKPKXmlDatabaseNameChanged;

FOUNDATION_EXTERN NSString *const kKPKXmlDatabaseDescription;
FOUNDATION_EXTERN NSString *const kKPKXmlDatabaseDescriptionChanged;
FOUNDATION_EXTERN NSString *const kKPKXmlDefaultUserName;
FOUNDATION_EXTERN NSString *const kKPKXmlDefaultUserNameChanged;
FOUNDATION_EXTERN NSString *const kKPKXmlMaintenanceHistoryDays;
FOUNDATION_EXTERN NSString *const kKPKXmlColor;
FOUNDATION_EXTERN NSString *const kKPKXmlMasterKeyChanged;
FOUNDATION_EXTERN NSString *const kKPKXmlMasterKeyChangeRecommendationInterval;
FOUNDATION_EXTERN NSString *const kKPKXmlMasterKeyChangeForceInterval;

FOUNDATION_EXTERN NSString *const kKPKXmlMemoryProtection;
FOUNDATION_EXTERN NSString *const kKPKXmlProtectTitle;
FOUNDATION_EXTERN NSString *const kKPKXmlProtectUserName;
FOUNDATION_EXTERN NSString *const kKPKXmlProtectPassword;
FOUNDATION_EXTERN NSString *const kKPKXmlProtectURL;
FOUNDATION_EXTERN NSString *const kKPKXmlProtectNotes;

FOUNDATION_EXTERN NSString *const kKPKXmlRecycleBinEnabled;
FOUNDATION_EXTERN NSString *const kKPKXmlRecycleBinUUID;
FOUNDATION_EXTERN NSString *const kKPKXmlRecycleBinChanged;
FOUNDATION_EXTERN NSString *const kKPKXmlEntryTemplatesGroup;
FOUNDATION_EXTERN NSString *const kKPKXmlEntryTemplatesGroupChanged;
FOUNDATION_EXTERN NSString *const kKPKXmlHistoryMaxItems;
FOUNDATION_EXTERN NSString *const kKPKXmlHistoryMaxSize;
FOUNDATION_EXTERN NSString *const kKPKXmlLastSelectedGroup;
FOUNDATION_EXTERN NSString *const kKPKXmlLastTopVisibleGroup;

#pragma mark Groups
FOUNDATION_EXTERN NSString *const kKPKXmlIsExpanded;
FOUNDATION_EXTERN NSString *const kKPKXmlDefaultAutoTypeSequence;
FOUNDATION_EXTERN NSString *const kKPKXmlEnableAutoType;
FOUNDATION_EXTERN NSString *const kKPKXmlEnableSearching;
FOUNDATION_EXTERN NSString *const kKPKXmlLastTopVisibleEntry;

FOUNDATION_EXTERN NSString *const kKPKXmlUUID;
FOUNDATION_EXTERN NSString *const kKPKXmlName;
FOUNDATION_EXTERN NSString *const kKPKXmlNotes;
FOUNDATION_EXTERN NSString *const kKPKXmlIconId;

#pragma mark Binaries
FOUNDATION_EXTERN NSString *const kKPKXmlBinary;
FOUNDATION_EXTERN NSString *const kKPKXmlBinaries;

#pragma mark Time
FOUNDATION_EXTERN NSString *const kKPKXmlTimes;
FOUNDATION_EXTERN NSString *const kKPKXmlLastModificationDate;
FOUNDATION_EXTERN NSString *const kKPKXmlCreationDate;
FOUNDATION_EXTERN NSString *const kKPKXmlLastAccessDate;
FOUNDATION_EXTERN NSString *const kKPKXmlExpirationDate;
FOUNDATION_EXTERN NSString *const kKPKXmlExpires;
FOUNDATION_EXTERN NSString *const kKPKXmlUsageCount;
FOUNDATION_EXTERN NSString *const kKPKXmlLocationChanged;

#pragma mark Generic
FOUNDATION_EXTERN NSString *const kKPKXmlKey;
FOUNDATION_EXTERN NSString *const kKPKXmlValue;
FOUNDATION_EXTERN NSString *const kKPKXmlData;

#pragma mark Attributes
FOUNDATION_EXTERN NSString *const kKPKXmlProtected; // Only used when stored as kdbx files.
FOUNDATION_EXTERN NSString *const kKPKXMLProtectInMemory; // Only used when stores as plain XML files.
FOUNDATION_EXTERN NSString *const kKPKXmlTrue;
FOUNDATION_EXTERN NSString *const kKPKXmlFalse;