//
//  KPKXmlElements.m
//  MacPass
//
//  Created by Michael Starke on 05/12/13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlElements.h"

#pragma mark Nodes
NSString *const kKPKXmlKeePassFile = @"KeePassFile";
NSString *const kKPKXmlRoot = @"Root";
NSString *const kKPKXmlHeaderHash = @"HeaderHash";
NSString *const kKPKXmlMeta = @"Meta";
NSString *const kKPKXmlGroup = @"Group";
NSString *const kKPKXmlGenerator = @"Generator";
NSString *const kKPKXmlDatabaseName = @"DatabaseName";
NSString *const kKPKXmlDatabaseNameChanged = @"DatabaseNameChanged";
NSString *const kKPKXmlDatabaseDescription = @"DatabaseDescription";
NSString *const kKPKXmlDatabaseDescriptionChanged = @"DatabaseDescriptionChanged";
NSString *const kKPKXmlDefaultUserName = @"DefaultUserName";
NSString *const kKPKXmlDefaultUserNameChanged = @"DefaultUserNameChanged";
NSString *const kKPKXmlMaintenanceHistoryDays = @"MaintenanceHistoryDays";
NSString *const kKPKXmlColor = @"Color";
NSString *const kKPKXmlMasterKeyChanged = @"MasterKeyChanged";
NSString *const kKPKXmlMasterKeyChangeRecommendationInterval = @"MasterKeyChangeRec";
NSString *const kKPKXmlMasterKeyChangeForceInterval = @"MasterKeyChangeForce";

NSString *const kKPKXmlMemoryProtection = @"MemoryProtection";
NSString *const kKPKXmlProtectTitle = @"ProtectTitle";
NSString *const kKPKXmlProtectUserName = @"ProtectUserName";
NSString *const kKPKXmlProtectPassword = @"ProtectPassword";
NSString *const kKPKXmlProtectURL = @"ProtectURL";
NSString *const kKPKXmlProtectNotes = @"ProtectNotes";

NSString *const kKPKXmlRecycleBinEnabled = @"RecycleBinEnabled";
NSString *const kKPKXmlRecycleBinUUID = @"RecycleBinUUID";
NSString *const kKPKXmlRecycleBinChanged = @"RecycleBinChanged";
NSString *const kKPKXmlEntryTemplatesGroup = @"EntryTemplatesGroup";
NSString *const kKPKXmlEntryTemplatesGroupChanged = @"EntryTemplatesGroupChanged";
NSString *const kKPKXmlHistoryMaxItems = @"HistoryMaxItems";
NSString *const kKPKXmlHistoryMaxSize = @"HistoryMaxSize";
NSString *const kKPKXmlLastSelectedGroup = @"LastSelectedGroup";
NSString *const kKPKXmlLastTopVisibleGroup = @"LastTopVisibleGroup";

NSString *const kKPKXmlIsExpanded = @"IsExpanded";
NSString *const kKPKXmlDefaultAutoTypeSequence = @"DefaultAutoTypeSequence";
NSString *const kKPKXmlEnableAutoType = @"EnableAutoType";
NSString *const kKPKXmlEnableSearching = @"EnableSearching";
NSString *const kKPKXmlLastTopVisibleEntry = @"LastTopVisibleEntry";

NSString *const kKPKXmlUUID = @"UUID";
NSString *const kKPKXmlName = @"Name";
NSString *const kKPKXmlNotes = @"Notes";
NSString *const kKPKXmlIconId = @"IconID";

#pragma mark Binaries
NSString *const kKPKXmlBinary = @"Binary";
NSString *const kKPKXmlBinaries = @"Binaries";

#pragma mark Time
NSString *const kKPKXmlTimes = @"Times";
NSString *const kKPKXmlLastModificationTime = @"LastModificationTime";
NSString *const kKPKXmlCreationTime = @"CreationTime";
NSString *const kKPKXmlLastAccessTime = @"LastAccessTime";
NSString *const kKPKXmlExpiryTime = @"ExpiryTime";
NSString *const kKPKXmlExpires = @"Expires";
NSString *const kKPKXmlUsageCount = @"UsageCount";
NSString *const kKPKXmlLocationChanged = @"LocationChanged";


#pragma mark Generic
NSString *const kKPKXmlKey = @"Key";
NSString *const kKPKXmlValue = @"Value";
NSString *const kKPKXmlData = @"Data";

#pragma mark Attributes
NSString *const kKPKXmlProtected        = @"Protected";
NSString *const kKPKXMLProtectInMemory  = @"ProtectInMemory";
NSString *const kKPKXmlTrue             = @"True";
NSString *const kKPKXmlFalse            = @"False";