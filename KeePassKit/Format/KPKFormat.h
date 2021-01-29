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
FOUNDATION_EXTERN uint32_t const kKPKKdbFileVersion;
FOUNDATION_EXTERN uint32_t const kKPKKdbFileVersionMask;
FOUNDATION_EXTERN uint32_t const kKPKKdbSignature1;
FOUNDATION_EXTERN uint32_t const kKPKKdbSignature2;

/**
 *  Signatrues and Data for the XML (Keepass2) file format
 */
FOUNDATION_EXTERN uint32_t const kKPKInvalidFileVersion;
FOUNDATION_EXTERN uint32_t const kKPKKdbxFileVersion3;
FOUNDATION_EXTERN uint32_t const kKPKKdbxFileVersion3CriticalMax;
FOUNDATION_EXTERN uint32_t const kKPKKdbxFileVersion4;
FOUNDATION_EXTERN uint32_t const kKPKKdbxFileVersion4CriticalMax;

FOUNDATION_EXTERN uint32_t const kKPKKdbxFileVersionCriticalMask;

FOUNDATION_EXTERN uint32_t const kKPKKdbxSignature1;
FOUNDATION_EXTERN uint32_t const kKPKKdbxSignature2;

typedef NS_ENUM( NSUInteger, KPKDatabaseFormat ) {
  KPKDatabaseFormatUnknown,
  KPKDatabaseFormatKdb,
  KPKDatabaseFormatKdbx,
};

typedef struct {
  KPKDatabaseFormat format; // KPDatabaseTypeUnknown if not determined (e.g. signatures don't match or file too small)
  NSUInteger version; // kKPKInvalidFileVersion if version cannot be read (e.g. file too small)
} KPKFileVersion;


FOUNDATION_EXTERN KPKFileVersion KPKFileVersionMax(KPKFileVersion a, KPKFileVersion b);
FOUNDATION_EXTERN KPKFileVersion KPKFileVersionMin(KPKFileVersion a, KPKFileVersion b);
FOUNDATION_EXTERN NSComparisonResult KPKFileVersionCompare(KPKFileVersion a, KPKFileVersion b);
FOUNDATION_EXTERN KPKFileVersion KPKMakeFileVersion(KPKDatabaseFormat format, NSUInteger version);

BOOL KPKIsValidFileInfo(KPKFileVersion fileInfo);

/**
 *  Key
 */
FOUNDATION_EXTERN uint32_t const kKPKKeyFileLength;

/**
 *  Default Keys used in the XML format
 */
FOUNDATION_EXTERN NSString *const kKPKTitleKey;
FOUNDATION_EXTERN NSString *const kKPKNameKey;
FOUNDATION_EXTERN NSString *const kKPKUsernameKey;
FOUNDATION_EXTERN NSString *const kKPKPasswordKey;
FOUNDATION_EXTERN NSString *const kKPKURLKey;
FOUNDATION_EXTERN NSString *const kKPKNotesKey;
FOUNDATION_EXTERN NSString *const kKPKUUIDKey;
FOUNDATION_EXTERN NSUInteger const kKPKDefaultEntryKeysCount;

#pragma mark Format
FOUNDATION_EXTERN NSString *const kKPKXmlKeePassFile;
FOUNDATION_EXTERN NSString *const kKPKXmlRoot;
FOUNDATION_EXTERN NSString *const kKPKXmlHeaderHash;
FOUNDATION_EXTERN NSString *const kKPKXmlGroup;
FOUNDATION_EXTERN NSString *const kKPKXmlEntry;

#pragma mark Metainformation
FOUNDATION_EXTERN NSString *const kKPKXmlSettingsChanged;

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
FOUNDATION_EXTERN NSString *const kKPKXmlMasterKeyChangeForceOnce;

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

#pragma mark Entries
FOUNDATION_EXTERN NSString *const kKPKXmlForegroundColor;
FOUNDATION_EXTERN NSString *const kKPKXmlBackgroundColor;
FOUNDATION_EXTERN NSString *const kKPKXmlOverrideURL;
FOUNDATION_EXTERN NSString *const kKPKXmlTags;

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

#pragma mark CustomData
FOUNDATION_EXTERN NSString *const kKPKXmlCustomData;
FOUNDATION_EXTERN NSString *const kKPKXmlCustomDataItem;

#pragma mark KeyFile
FOUNDATION_EXTERN NSString *const kKPKXmlKeyFile;

#pragma mark Generic
FOUNDATION_EXTERN NSString *const kKPKXmlVersion;
FOUNDATION_EXTERN NSString *const kKPKXmlKey;
FOUNDATION_EXTERN NSString *const kKPKXmlValue;
FOUNDATION_EXTERN NSString *const kKPKXmlData;
FOUNDATION_EXTERN NSString *const kKPKXmlEnabled;
FOUNDATION_EXTERN NSString *const kKPKXmlString;
FOUNDATION_EXTERN NSString *const kKPKXmlHash;
FOUNDATION_EXTERN NSString *const kKPKXmlMeta;

#pragma mark Attributes
FOUNDATION_EXTERN NSString *const kKPKXmlProtected; // Only used when stored as kdbx files.
FOUNDATION_EXTERN NSString *const kKPKXmlProtectInMemory; // Only used when stores as plain XML files.
FOUNDATION_EXTERN NSString *const kKPKXmlTrue;
FOUNDATION_EXTERN NSString *const kKPKXmlFalse;
FOUNDATION_EXTERN NSString *const kKPKXmlCompressed;

#pragma mark Special Attributes
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyOTPOAuthURL;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyHmacOTPSecret;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyHmacOTPSecretHex;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyHmacOTPSecretBase32;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyHmacOTPSecretBase64;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyHmacOTPCounter;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPSecret;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPSecretHex;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPSecretBase32;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPSecretBase64;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPLength;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPPeriod;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPAlgorithm;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPSeed;
FOUNDATION_EXTERN NSString *const kKPKAttributeKeyTimeOTPSettings;

FOUNDATION_EXTERN NSString *const kKPKAttributeValueTimeOTPHmacSha1;
FOUNDATION_EXTERN NSString *const kKPKAttributeValueTimeOTPHmacSha256;
FOUNDATION_EXTERN NSString *const kKPKAttributeValueTimeOTPHmacSha512;

/**
 *  Referemce Keys used for Referencing attributes inside entries
 */
#pragma mark Reference Keys
FOUNDATION_EXTERN NSString *const kKPKReferencePrefix;
FOUNDATION_EXTERN NSString *const kKPKReferenceTitleKey;
FOUNDATION_EXTERN NSString *const kKPKReferenceUsernameKey;
FOUNDATION_EXTERN NSString *const kKPKReferencePasswordKey;
FOUNDATION_EXTERN NSString *const kKPKReferenceURLKey;
FOUNDATION_EXTERN NSString *const kKPKReferenceNotesKey;
FOUNDATION_EXTERN NSString *const kKPKReferenceUUIDKey;
FOUNDATION_EXTERN NSString *const kKPKReferenceCustomFieldKey;

/**
 *  Placeholder keys
 */
#pragma mark Placeholder
FOUNDATION_EXTERN NSString *const kKPKPlaceholderUUID;

FOUNDATION_EXTERN NSString *const kKPKPlaceholderDatabasePath;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderDatabaseFolder;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderDatabaseName;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderDatabaseBasename;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderDatabaseFileExtension;

FOUNDATION_EXTERN NSString *const kKPKPlaceholderSelectedGroup;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderSelectedGroupPath;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderSelectedGroupNotes;

FOUNDATION_EXTERN NSString *const kKPKPlaceholderGroup;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderGroupPath;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderGroupNotes;

FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickChars;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsSpearator;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionDelemiter;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionID;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionCountShort;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionCount;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionHide;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionConvert;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionConvertOffset;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickCharsOptionConvertFormat;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderPickField;

FOUNDATION_EXTERN NSString *const kKPKPlaceholderHMACOTP;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderTIMEOTP;
FOUNDATION_EXTERN NSString *const kKPKPlaceholderTOTP;


#pragma mark Autotype
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
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortSpace;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortPlus;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortCaret;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortPercent;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortTilde;

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
FOUNDATION_EXTERN NSString *const kKPKAutotypeClearField;

/* Value-Commands - those strings aren't encosed in {} so you should add them yourself if you need them! */
FOUNDATION_EXTERN NSString *const kKPKAutotypeDelay;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualNonExtendedKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualExtendedKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeActivateApplication;

/**
 Format class.
 Holds all allowed keys for an element.
 */
@interface KPKFormat : NSObject
/**
 @returns The shared format instance
 */
@property (class, readonly, strong) KPKFormat *sharedFormat;
/**
 Determines the file version for the given raw file data

 @param data file data for version inspection
 @return file version of the data. KPKFileVersion.format is set to KPKDatabaseFormatUnknown if no version was determines. Values in KPKFileVersion.format are only valid if version is not unknown
 */
- (KPKFileVersion)fileVersionForData:(NSData *)data;
/**
 @returns A set containing the strings that are default keys for enty attributes
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *entryDefaultKeys;
/**
 Retrieves the index of the default attribute

 @param key default attribute key
 @return index of the key, NSNotFound if an invalid key was supplied
 */
- (NSInteger)indexForDefaultKey:(NSString *)key;

@end
