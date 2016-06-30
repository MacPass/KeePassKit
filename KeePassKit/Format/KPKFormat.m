//
//  KPKFormat.m
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

#import "KPKFormat.h"
#import "KPKLegacyFormat.h"
#import "KPKXmlFormat.h"

#pragma mark Signatures/Format
uint32_t const kKPKBinaryFileVersion      = 0x00030004;
uint32_t const kKPKBinaryFileVersionMask  = 0xFFFFFF00;
uint32_t const kKPKBinarySignature1       = 0x9AA2D903;
uint32_t const kKPKBinarySignature2       = 0xB54BFB65;

uint32_t const kKPKXMLFileVersion             = 0x00030001;
uint32_t const kKPKXMLFileVersionCriticalMax  = 0x00030000;
uint32_t const kKPKXMLFileVersionCriticalMask = 0xFFFF0000;

uint32_t const kKPKXMLSignature1 = 0x9AA2D903;
uint32_t const kKPKXMLSignature2 = 0xB54BFB67;

uint32_t const kKPKKeyFileLength = 32;

#pragma mark Attribute Keys
NSString *const kKPKTitleKey     = @"Title";
NSString *const kKPKNameKey      = @"Name";
NSString *const kKPKUsernameKey  = @"UserName";
NSString *const kKPKPasswordKey  = @"Password";
NSString *const kKPKURLKey       = @"URL";
NSString *const kKPKNotesKey     = @"Notes";
NSString *const kKPKUUIDKey      = @"UUID";
NSUInteger const kKPKDefaultEntryKeysCount = 5;


#pragma mark Nodes
NSString *const kKPKXmlKeePassFile = @"KeePassFile";
NSString *const kKPKXmlRoot = @"Root";
NSString *const kKPKXmlHeaderHash = @"HeaderHash";
NSString *const kKPKXmlMeta = @"Meta";
NSString *const kKPKXmlGroup = @"Group";
NSString *const kKPKXmlEntry = @"Entry";
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
NSString *const kKPKXmlBinary   = @"Binary";
NSString *const kKPKXmlBinaries = @"Binaries";
NSString *const kKPKXmlBinaryId = @"ID";

#pragma mark CustomIcons
NSString *const kKPKXmlCustomIconUUID = @"CustomIconUUID";
NSString *const kKPKXmlCustomIcons = @"CustomIcons";
NSString *const kKPKXmlIcon = @"Icon";
NSString *const kKPKXmlIconReference = @"Ref";

#pragma mark DeletedObjects
NSString *const kKPKXmlDeletedObjects = @"DeletedObjects";
NSString *const kKPKXmlDeletedObject = @"DeletedObject";
NSString *const kKPKXmlDeletionTime = @"DeletionTime";

#pragma mark Time
NSString *const kKPKXmlTimes = @"Times";
NSString *const kKPKXmlLastModificationDate = @"LastModificationTime";
NSString *const kKPKXmlCreationDate = @"CreationTime";
NSString *const kKPKXmlLastAccessDate = @"LastAccessTime";
NSString *const kKPKXmlExpirationDate = @"ExpiryTime";
NSString *const kKPKXmlExpires = @"Expires";
NSString *const kKPKXmlUsageCount = @"UsageCount";
NSString *const kKPKXmlLocationChanged = @"LocationChanged";

#pragma mark Autotype
NSString *const kKPKXmlAutotype = @"Autotype";
NSString *const kKPKXmlDefaultSequence = @"DefaultSequence";
NSString *const kKPKXmlDataTransferObfuscation = @"DataTransferObfuscation";
NSString *const kKPKXmlWindow = @"Window";
NSString *const kKPKXmlAssociation = @"Association";
NSString *const kKPKXmlKeystrokeSequence = @"KeystrokeSequence";

#pragma mark History
NSString *const kKPKXmlHistory = @"History";

#pragma mark Generic
NSString *const kKPKXmlVersion = @"Version";
NSString *const kKPKXmlKey = @"Key";
NSString *const kKPKXmlValue = @"Value";
NSString *const kKPKXmlData = @"Data";
NSString *const kKPKXmlEnabled = @"Enabled";

#pragma mark Attributes
NSString *const kKPKXmlProtected        = @"Protected";
NSString *const kKPKXMLProtectInMemory  = @"ProtectInMemory";
NSString *const kKPKXmlTrue             = @"True";
NSString *const kKPKXmlFalse            = @"False";
NSString *const kKPKXmlCompressed       = @"Compressed";

#pragma mark Reference Keys

NSString *const kKPKReferencePrefix         = @"REF:";
NSString *const kKPKReferenceTitleKey       = @"T";
NSString *const kKPKReferenceUsernameKey    = @"U";
NSString *const kKPKReferencePasswordKey    = @"P";
NSString *const kKPKReferenceURLKey         = @"A";
NSString *const kKPKReferenceNotesKey       = @"N";
NSString *const kKPKReferenceUUIDKey        = @"I";
NSString *const kKPKReferenceCustomFieldKey = @"O";

#pragma mark Autotype commands
/*
 Tab	{TAB}
 Enter	{ENTER} or ~
 Arrow Up	{UP}
 Arrow Down	{DOWN}
 Arrow Left	{LEFT}
 Arrow Right	{RIGHT}
 Insert	{INSERT} or {INS}
 Delete	{DELETE} or {DEL}
 Home	{HOME}
 End	{END}
 Page Up	{PGUP}
 Page Down	{PGDN}
 Backspace	{BACKSPACE}, {BS} or {BKSP}
 Break	{BREAK}
 Caps-Lock	{CAPSLOCK}
 Escape	{ESC}
 Windows Key	{WIN} (equ. to {LWIN})
 Windows Key: left, right	{LWIN}, {RWIN}
 Apps / Menu	{APPS}
 Help	{HELP}
 Numlock	{NUMLOCK}
 Print Screen	{PRTSC}
 Scroll Lock	{SCROLLLOCK}
 F1 - F16	{F1} - {F16}
 Numeric Keypad +	{ADD}
 Numeric Keypad -	{SUBTRACT}
 Numeric Keypad *	{MULTIPLY}
 Numeric Keypad /	{DIVIDE}
 Numeric Keypad 0 to 9	{NUMPAD0} to {NUMPAD9}
 Shift	+
 Ctrl	^
 Alt	%
 +	{+}
 ^	{^}
 %	{%}
 ~	{~}
 (, )	{(}, {)}
 [, ]	{[}, {]}
 {, }	{{}, {}}
 
 special commands:
 
 {DELAY X}	Delays X milliseconds.
 {CLEARFIELD}	Clears the contents of the edit control that currently has the focus (only single-line edit controls).
 {VKEY X}
 */

/* Shorts */
NSString *const kKPKAutotypeShortShift = @"+";
NSString *const kKPKAutotypeShortControl = @"^";
NSString *const kKPKAutotypeShortAlt = @"%";
NSString *const kKPKAutotypeShortEnter = @"~";
NSString *const kKPKAutotypeShortInsert = @"{INS}";
NSString *const kKPKAutotypeShortDelete = @"{DEL}";
NSString *const kKPKAutotypeShortBackspace = @"{BS}";
NSString *const kKPKAutotypeShortBackspace2 = @"{BKSP}";
NSString *const kKPKAutotypeShortCurlyBracketLeft = @"{{}";
NSString *const kKPKAutotypeShortCurlyBracketRight = @"{}}";
NSString *const kKPKAutotypeShortSpace = @" ";
NSString *const kKPKAutotypeShortPlus = @"{+}";
NSString *const kKPKAutotypeShortCaret = @"{^}";
NSString *const kKPKAutotypeShortPercent = @"{%}";
NSString *const kKPKAutotypeShortTilde = @"{~}";

/* Extended Formats*/
NSString *const kKPKAutotypeShift = @"{SHIFT}";
NSString *const kKPKAutotypeControl = @"{CONTROL}";
NSString *const kKPKAutotypeAlt = @"{ALT}";
NSString *const kKPKAutotypeEnter = @"{ENTER}";
NSString *const kKPKAutotypeInsert = @"{INSERT}";
NSString *const kKPKAutotypeDelete = @"{DELETE}";
NSString *const kKPKAutotypeBackspace = @"{BACKSPACE}";
NSString *const kKPKAutotypeSpace = @"{SPACE}";

/* Other Keys */
NSString *const kKPKAutotypeTab = @"{TAB}";
NSString *const kKPKAutotypeUp = @"{UP}";
NSString *const kKPKAutotypeDown = @"{DOWN}";
NSString *const kKPKAutotypeLeft = @"{LEFT}";
NSString *const kKPKAutotypeRight = @"{RIGHT}";
NSString *const kKPKAutotypeHome = @"{HOME}";
NSString *const kKPKAutotypeEnd = @"{END}";
NSString *const kKPKAutotypePageUp = @"{PGUP}";
NSString *const kKPKAutotypePageDown = @"{PGDOWN}";
NSString *const kKPKAutotypeBreak = @"{BREAK}";
NSString *const kKPKAutotypeCapsLock = @"{CAPSLOCK}";
NSString *const kKPKAutotypeEscape = @"{ESC}";
NSString *const kKPKAutotypeWindows = @"{WIN}";
NSString *const kKPKAutotypeLeftWindows = @"{LWIN}";
NSString *const kKPKAutotypeRightWindows = @"{RWIN}";
NSString *const kKPKAutotypeApps = @"{APPS}";
NSString *const kKPKAutotypeHelp = @"{HELP}";
NSString *const kKPKAutotypeNumlock = @"{NUMLOCK}";
NSString *const kKPKAutotypePrintScreen = @"{PRTSC}";
NSString *const kKPKAutotypeScrollLock = @"{SCROLLLOCK}";
NSString *const kKPKAutotypeFunctionMaskRegularExpression = @"\\{F(1?[0-9])\\}"; //1-16

/* Keypad */
NSString *const kKPKAutotypeKeypaddAdd = @"{ADD}";
NSString *const kKPKAutotypeKeypaddSubtract = @"{SUBTRACT}";
NSString *const kKPKAutotypeKeypaddMultiply = @"{MULTIPLY}";
NSString *const kKPKAutotypeKeypaddDivide = @"{DIVIDE}";
NSString *const kKPKAutotypeKeypaddNumberMask = @"\\{NUMPAD[0-9]\\}"; // 0-9

/* Symbols */
NSString *const kKPKAutotypePlus = @"{PLUS}";
NSString *const kKPKAutotypeCaret = @"{CARET}";
NSString *const kKPKAutotypePercent = @"{PERCENT}";
NSString *const kKPKAutotypeTilde = @"{TILDE}";
NSString *const kKPKAutotypeRoundBracketLeft = @"{(}";
NSString *const kKPKAutotypeRoundBracketRight = @"{)}";
NSString *const kKPKAutotypeSquareBracketLeft = @"{[}";
NSString *const kKPKAutotypeSquareBracketRight = @"{]}";
NSString *const kKPKAutotypeCurlyBracketLeft = @"{CURLYLEFT}";
NSString *const kKPKAutotypeCurlyBracketRight = @"{CURLYRIGHT}";

/* Special Commands */
NSString *const kKPKAutotypeClearField = @"{CLEARFIELD}";

/* Value Commands without Brackets to use in Matches */
NSString *const kKPKAutotypeDelay = @"DELAY";
NSString *const kKPKAutotypeVirtualKey = @"VKEY";
NSString *const kKPKAutotypeVirtualNonExtendedKey = @"VKEY-NX";
NSString *const kKPKAutotypeVirtualExtendedKey = @"VKEY-EX";

/*
 Windows Key	{WIN} (equ. to {LWIN})
 Windows Key: left, right	{LWIN}, {RWIN}
 +	{+}
 ^	{^}
 %	{%}
 ~	{~}
 (, )	{(}, {)}
 [, ]	{[}, {]}
 {, }	{{}, {}}
 
 */

@implementation KPKFormat

+ (instancetype)sharedFormat {
  static id formatInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatInstance = [[self _alloc] _init];
  });
  return formatInstance;
}

- (instancetype)_init {
  self = [super init];
  if (self) {
    _entryDefaultKeys = @[ kKPKTitleKey, kKPKUsernameKey, kKPKPasswordKey, kKPKURLKey, kKPKNotesKey ];
  }
  return self;
}

+ (instancetype)_alloc {
  return [super allocWithZone:nil];
}

+ (instancetype)allocWithZone:(NSZone *)zone {
  return [self sharedFormat];
}

- (NSInteger)indexForDefaultKey:(NSString *)key {
  return [self.entryDefaultKeys indexOfObject:key];
}

- (KPKVersion)databaseVersionForData:(NSData *)data {
  uint32_t signature1;
  uint32_t signature2;
  
  if(data.length < 7 ) {
    return KPKUnknownVersion;
  }
  
  [data getBytes:&signature1 range:NSMakeRange(0, 4)];
  [data getBytes:&signature2 range:NSMakeRange(4, 4)];
  signature1 = CFSwapInt32LittleToHost(signature1);
  signature2 = CFSwapInt32LittleToHost(signature2);
  
  if (signature1 == kKPKBinarySignature1 && signature2 == kKPKBinarySignature2) {
    return KPKLegacyVersion;
  }
  if (signature1 == kKPKXMLSignature1 && signature2 == kKPKXMLSignature2 ) {
    return KPKXmlVersion;
  }
  return KPKUnknownVersion;
}

- (uint32_t)fileVersionForData:(NSData *)data {
  uint32_t version;
  [data getBytes:&version range:NSMakeRange(8, 4)];
  version = CFSwapInt32LittleToHost(version);
  return version;
}

@end
