//
//  KPKFormat.h
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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

@import Foundation;
/**
 *  Signatures for the Binary (Keepass1) file format
 */
FOUNDATION_EXTERN uint32_t const kKPKBinaryFileVersion;
FOUNDATION_EXTERN uint32_t const kKPKBinaryFileVersionMask;
FOUNDATION_EXTERN uint32_t const kKPKBinarySignature1;
FOUNDATION_EXTERN uint32_t const kKPKBinarySignature2;

/**
 *  Signatrues and Data for the XML (Keepass2) file format
 */
FOUNDATION_EXPORT uint32_t const kKPKInvalidFileVersion;
FOUNDATION_EXTERN uint32_t const kKPKXMLFileVersion3;
FOUNDATION_EXTERN uint32_t const kKPKXMLFileVersion3CriticalMax;
FOUNDATION_EXTERN uint32_t const kKPKXMLFileVersion4;
FOUNDATION_EXTERN uint32_t const kKPKXMLFileVersion4CriticalMax;

FOUNDATION_EXTERN uint32_t const kKPKXMLFileVersionCriticalMask;

FOUNDATION_EXTERN uint32_t const kKPKXMLSignature1;
FOUNDATION_EXTERN uint32_t const kKPKXMLSignature2;

typedef NS_ENUM( NSUInteger, KPKDatabaseType ) {
  KPKDatabaseTypeUnknown,
  KPKDatabaseTypeBinary,
  KPKDatabaseTypeXml,
};

typedef struct {
  KPKDatabaseType type; // KPDatabaseTypeUnknown if not determined (e.g. signatures don't match or file too small)
  NSUInteger version; // kKPKInvalidFileVersion if version cannot be read (e.g. file too small)
} KPKFileInfo;

BOOL KPKIsValidFileInfo(KPKFileInfo fileInfo);

/**
 *  Key
 */
FOUNDATION_EXTERN uint32_t const kKPKKeyFileLength;

/**
 *  Default Keys used in the XML format
 */
FOUNDATION_EXPORT NSString *const kKPKTitleKey;
FOUNDATION_EXPORT NSString *const kKPKNameKey;
FOUNDATION_EXPORT NSString *const kKPKUsernameKey;
FOUNDATION_EXPORT NSString *const kKPKPasswordKey;
FOUNDATION_EXPORT NSString *const kKPKURLKey;
FOUNDATION_EXPORT NSString *const kKPKNotesKey;
FOUNDATION_EXPORT NSString *const kKPKUUIDKey;
FOUNDATION_EXPORT NSUInteger const kKPKDefaultEntryKeysCount;

#pragma mark Format
FOUNDATION_EXTERN NSString *const kKPKXmlKeePassFile;
FOUNDATION_EXTERN NSString *const kKPKXmlRoot;
FOUNDATION_EXTERN NSString *const kKPKXmlHeaderHash;
FOUNDATION_EXTERN NSString *const kKPKXmlMeta;
FOUNDATION_EXTERN NSString *const kKPKXmlGroup;
FOUNDATION_EXTERN NSString *const kKPKXmlEntry;

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
FOUNDATION_EXTERN NSString *const kKPKXmlBinaryId;

#pragma mark CustomIcons
FOUNDATION_EXTERN NSString *const kKPKXmlCustomIconUUID;
FOUNDATION_EXTERN NSString *const kKPKXmlCustomIcons;
FOUNDATION_EXTERN NSString *const kKPKXmlIcon;
FOUNDATION_EXTERN NSString *const kKPKXmlIconReference;

#pragma mark DeletedObjects
FOUNDATION_EXTERN NSString *const kKPKXmlDeletedObjects;
FOUNDATION_EXTERN NSString *const kKPKXmlDeletedObject;
FOUNDATION_EXTERN NSString *const kKPKXmlDeletionTime;

#pragma mark Time
FOUNDATION_EXTERN NSString *const kKPKXmlTimes;
FOUNDATION_EXTERN NSString *const kKPKXmlLastModificationDate;
FOUNDATION_EXTERN NSString *const kKPKXmlCreationDate;
FOUNDATION_EXTERN NSString *const kKPKXmlLastAccessDate;
FOUNDATION_EXTERN NSString *const kKPKXmlExpirationDate;
FOUNDATION_EXTERN NSString *const kKPKXmlExpires;
FOUNDATION_EXTERN NSString *const kKPKXmlUsageCount;
FOUNDATION_EXTERN NSString *const kKPKXmlLocationChanged;

#pragma mark Autotype
FOUNDATION_EXTERN NSString *const kKPKXmlAutotype;
FOUNDATION_EXTERN NSString *const kKPKXmlDefaultSequence;
FOUNDATION_EXTERN NSString *const kKPKXmlDataTransferObfuscation;
FOUNDATION_EXTERN NSString *const kKPKXmlWindow;
FOUNDATION_EXTERN NSString *const kKPKXmlAssociation;
FOUNDATION_EXTERN NSString *const kKPKXmlKeystrokeSequence;

#pragma mark History
FOUNDATION_EXTERN NSString *const kKPKXmlHistory;

#pragma mark Generic
FOUNDATION_EXTERN NSString *const kKPKXmlVersion;
FOUNDATION_EXTERN NSString *const kKPKXmlKey;
FOUNDATION_EXTERN NSString *const kKPKXmlValue;
FOUNDATION_EXTERN NSString *const kKPKXmlData;
FOUNDATION_EXTERN NSString *const kKPKXmlEnabled;

#pragma mark Attributes
FOUNDATION_EXTERN NSString *const kKPKXmlProtected; // Only used when stored as kdbx files.
FOUNDATION_EXTERN NSString *const kKPKXMLProtectInMemory; // Only used when stores as plain XML files.
FOUNDATION_EXTERN NSString *const kKPKXmlTrue;
FOUNDATION_EXTERN NSString *const kKPKXmlFalse;
FOUNDATION_EXTERN NSString *const kKPKXmlCompressed;

/**
 *  Referemce Keys used for Referencing attributes inside entries
 */
FOUNDATION_EXPORT NSString *const kKPKReferencePrefix;
FOUNDATION_EXPORT NSString *const kKPKReferenceTitleKey;
FOUNDATION_EXPORT NSString *const kKPKReferenceUsernameKey;
FOUNDATION_EXPORT NSString *const kKPKReferencePasswordKey;
FOUNDATION_EXPORT NSString *const kKPKReferenceURLKey;
FOUNDATION_EXPORT NSString *const kKPKReferenceNotesKey;
FOUNDATION_EXPORT NSString *const kKPKReferenceUUIDKey;
FOUNDATION_EXPORT NSString *const kKPKReferenceCustomFieldKey;

/**
 *  Autotype Commands
 */

/* Short versions */
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortShift;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortControl;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortAlt;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortEnter;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortInsert;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortDelete;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortBackspace;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortBackspace2;
FOUNDATION_EXPORT NSString *const kKPKAutotypeShortSpace;
FOUNDATION_EXPORT NSString *const kKPKAutotypeShortPlus;
FOUNDATION_EXPORT NSString *const kKPKAutotypeShortCaret;
FOUNDATION_EXPORT NSString *const kKPKAutotypeShortPercent;
FOUNDATION_EXPORT NSString *const kKPKAutotypeShortTilde;

/* Normalized */
FOUNDATION_EXTERN NSString *const kKPKAutotypeEnter;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShift;
FOUNDATION_EXTERN NSString *const kKPKAutotypeControl;
FOUNDATION_EXTERN NSString *const kKPKAutotypeAlt;
FOUNDATION_EXTERN NSString *const kKPKAutotypeInsert;
FOUNDATION_EXTERN NSString *const kKPKAutotypeDelete;
FOUNDATION_EXTERN NSString *const kKPKAutotypeBackspace;
FOUNDATION_EXTERN NSString *const kKPKAutotypeSpace;

/* Other Keys */
FOUNDATION_EXTERN NSString *const kKPKAutotypeTab;
FOUNDATION_EXTERN NSString *const kKPKAutotypeUp;
FOUNDATION_EXTERN NSString *const kKPKAutotypeDown;
FOUNDATION_EXTERN NSString *const kKPKAutotypeLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeHome;
FOUNDATION_EXTERN NSString *const kKPKAutotypeEnd;
FOUNDATION_EXTERN NSString *const kKPKAutotypePageUp;
FOUNDATION_EXTERN NSString *const kKPKAutotypePageDown;
FOUNDATION_EXTERN NSString *const kKPKAutotypeBreak;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCapsLock;
FOUNDATION_EXTERN NSString *const kKPKAutotypeEscape;
FOUNDATION_EXTERN NSString *const kKPKAutotypeWindows;
FOUNDATION_EXTERN NSString *const kKPKAutotypeLeftWindows;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRightWindows;
FOUNDATION_EXTERN NSString *const kKPKAutotypeApps;
FOUNDATION_EXTERN NSString *const kKPKAutotypeHelp;
FOUNDATION_EXTERN NSString *const kKPKAutotypeNumlock;
FOUNDATION_EXTERN NSString *const kKPKAutotypePrintScreen;
FOUNDATION_EXTERN NSString *const kKPKAutotypeScrollLock;
FOUNDATION_EXTERN NSString *const kKPKAutotypeFunctionMaskRegularExpression; //1-16

/* Keypad */
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddAdd;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddSubtract;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddMultiply;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddDivide;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddNumberMaskRegularExpression; // 0-9

/* Symbols */
FOUNDATION_EXTERN NSString *const kKPKAutotypePlus;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCaret;
FOUNDATION_EXTERN NSString *const kKPKAutotypePercent;
FOUNDATION_EXTERN NSString *const kKPKAutotypeTilde;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRoundBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRoundBracketRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeSquareBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeSquareBracketRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortCurlyBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortCurlyBracketRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCurlyBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCurlyBracketRight;

/* Special Commands */
FOUNDATION_EXPORT NSString *const kKPKAutotypeClearField;

/* Value-Commands*/
FOUNDATION_EXTERN NSString *const kKPKAutotypeDelay;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualNonExtendedKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualExtendedKey;

/**
 Format class.
 Holds all allowed keys for an element.
 */
@interface KPKFormat : NSObject
/**
 @returns The shared format instance
 */
+ (instancetype)sharedFormat;

- (KPKFileInfo)fileInfoForData:(NSData *)data;
/**
 @returns A set containing the strings that are default keys for enty attributes
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *entryDefaultKeys;
- (NSInteger)indexForDefaultKey:(NSString *)key;

@end
