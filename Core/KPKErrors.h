//
//  KPKErrors.h
//  KeePassKit
//
//  Created by Michael Starke on 13.07.13.
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

#ifndef MacPass_KPKErrors_h
#define MacPass_KPKErrors_h

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const KPKErrorDomain;

FOUNDATION_EXTERN_INLINE void KPKCreateError( NSError **errorPtr, NSInteger errorCode, NSString *localizedKey, char *comment);

typedef NS_ENUM( NSUInteger, KPKErrorCode ) {
  KPKErrorNoData = 1000, // No data given
  KPKErrorUnknownFileFormat, // The file format is unknown
  KPKErrorHeaderCorrupted, // The header is Corrupted
  KPKErrorWriteFailed, // Could write the File
  KPKErrorDecryptionFaild, // Failed to decrypt the data stream
  KPKErrorEncryptionFaild, // Faled to encrypt the data stream
  KPKErrorDatabaseParsingFailed, // The XML-Database couldn be parsed
  KPKerrorXMLKeyUnsupportedVersion, // The XML-Keyfile is an usupported version
  KPKErrorXMLKeyKeyElementMissing, // The XML-Keyfile has no key element
  KPKErrorXMLKeyDataElementMissing, // The XML-Keyfile has no data element
  KPKErrorXMLKeyDataParsingError, // The XML-data element couldn't be parsed
  KPKErrorUnsupportedDatabaseVersion, // The database version is to high/low
  KPKErrorUnsupportedCipher, // The header specifies a unsupported and/or wrong chipher methed
  KPKErrorUnsupportedCompressionAlgorithm, // The header specifies an unsupporte and/or wrong compressoing algorithm
  KPKErrorUnsupportedRandomStream, // The header specifies an unsupporte stream or it's corrupted
  KPKErrorPasswordAndOrKeyfileWrong, // Password and or keyfile is wrong
  KPKErrorIntegrityCheckFaild, // The startbytes in the header aren't matching the AES stream-start
  KPKErrorXMLKeePassFileElementMissing, // the Keepass root element is missing
  KPKErrorXMLRootElementMissing, // The root Elemetn is missing;
  KPKErrorXMLMetaElementMissing, // The root element has no meta entry
  KPKErrorXMLGroupElementMissing, // no Group element found
  KPKErrorXMLInvalidHeaderFieldSize, // KDBX Header field size missmatch
  KPKErrorXMLInvalidHeaderFieldType, // KDBX Header field type unknown
  KPKErrorLegacyInvalidFieldType, // KDB Invalid field type
  KPKErrorLegacyInvalidFieldSize, // KDB Invalid field size
  KPKErrorLegacyHeaderHashCorrupted, // Header missmatch
  KPKErrorLegacyCorruptTree, // Tree sturcture is corrupted
};

#endif
