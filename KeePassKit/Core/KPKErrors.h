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

//void KPKCreateError( NSError **errorPtr, NSInteger errorCode, NSString *localizedKey, char *comment);
void KPKCreateError( NSError * __autoreleasing *errorPtr, NSInteger errorCode);

typedef NS_ENUM( NSUInteger, KPKErrorCode ) {
  KPKErrorAESDecryptionFailed = 1000, // Failed to decrypt the file using AES
  KPKErrorAESEncryptionFailed, // Failed to encrypt the data using AES
  KPKErrorAttributeKeyValidationFailed, // Validation of attribute key failed
  KPKErrorDecryptionFailed, // Failed to decrypt the data stream
  KPKErrorEncryptionFailed, // Failed to encrypt the data
  KPKErrorIntegrityCheckFailed, // The startbytes in the header aren't matching the AES stream-start
  KPKErrorKdbCorruptTree, // Tree sturcture is corrupted
  KPKErrorKdbHeaderTruncated, // The header (and thus the file) was truncated
  KPKErrorKdbInvalidFieldSize, // KDB Invalid field size
  KPKErrorKdbInvalidFieldType, // KDB Invalid field type
  KPKErrorKdbxCorruptedContentStream, // The content data was corrupted (KDBX3.1)
  KPKErrorKdbxCorruptedEncryptionStream, // The encrypted data was corrupted (KDBX4)
  KPKErrorKdbxCorruptedInnerHeader, // the inner header is corrupted
  KPKErrorKdbxCorrutpedPublicCustomData, // The custom data stored in the header is corrupted
  KPKErrorKdbxGroupElementMissing, // no Group element found
  KPKErrorKdbxHeaderHashVerificationFailed, // The header hash does not match the one provieded in the database
  KPKErrorKdbxInvalidHeaderFieldSize, // KDBX Header field size missmatch
  KPKErrorKdbxInvalidHeaderFieldType, // KDBX Header field type unknown
  KPKErrorKdbxInvalidInnerHeaderFieldType, // invalid field type in the inner header
  KPKErrorKdbxInvalidKeyDerivationData, // The key derivation header data is invalid
  KPKErrorKdbxKeePassFileElementMissing, // the Keepass root element is missing
  KPKErrorKdbxKeyMetaElementMissing, // The key file is missing the meta element
  KPKErrorKdbxKeyKeyFileElementMissing, // The Key file element is missing form the KeyFile
  KPKErrorKdbxKeyHashAttributeMissing, // The Xml-data did not contain a hash for the key data (Version 2.0)
  KPKErrorKdbxKeyHashAttributeWrongSize, // The Xml-data wasn't the correct size
  KPKErrorKdbxKeyDataCorrupted, // The XML-data did not matcht the hash and is considered corrupted
  KPKErrorKdbxKeyDataElementMissing, // The XML-Keyfile has no data element
  KPKErrorKdbxKeyDataParsingError, // The XML-data element couldn't be parsed
  KPKErrorKdbxKeyKeyElementMissing, // The XML-Keyfile has no key element
  KPKErrorKdbxKeyVersionElementMissing, // The XML-keyfile has no version element
  KPKErrorKdbxKeyUnsupportedVersion, // The XML-Keyfile is an usupported version
  KPKErrorKdbxMalformedXmlStructure, // KDBX XML file has malformed structure
  KPKErrorKdbxMetaElementMissing, // The root element has no meta entry
  KPKErrorKdbxRootElementMissing, // The root Elemetn is missing;
  KPKErrorKeyDerivationFailed, // The key derivation failed
  KPKErrorNoData, // No data given
  KPKErrorNoKeyData, // The key file does not contain any data
  KPKErrorNoXmlData, // The data is no XML file, this error is mostly used internally
  KPKErrorPasswordAndOrKeyfileWrong, // Password and or keyfile is wrong
  KPKErrorUnknownFileFormat, // The file format is unknown
  KPKErrorUnsupportedCipher, // The header specifies a unsupported and/or wrong chipher methed
  KPKErrorUnsupportedCompressionAlgorithm, // The header specifies an unsupporte and/or wrong compressoing algorithm
  KPKErrorUnsupportedDatabaseVersion, // The database version is to high/low
  KPKErrorUnsupportedKeyDerivation, // The header specifies an unsupported and/or wrong key derivation method
  KPKErrorUnsupportedRandomStream, // The header specifies an unsupporte stream or it's corrupted
  KPKErrorWindowTitleFormatValidationFailed, // The Window title for autotype is not supported
  KPKErrorWrongIVVectorSize, // The header has a wrong size of the IV vector for the specified cipher
};

#endif
