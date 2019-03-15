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
  KPKErrorNoData = 1000, // No data given
  KPKErrorUnknownFileFormat, // The file format is unknown
  KPKErrorEncryptionFailed, // Failed to encrypt the data
  KPKErrorAESEncryptionFailed, // Failed to encrypt the data using AES
  KPKErrorDecryptionFailed, // Failed to decrypt the data stream
  KPKErrorAESDecryptionFailed, // Failed to decrypt the file using AES
  KPKErrorKdbxKeyUnsupportedVersion, // The XML-Keyfile is an usupported version
  KPKErrorKdbxKeyKeyElementMissing, // The XML-Keyfile has no key element
  KPKErrorKdbxKeyDataElementMissing, // The XML-Keyfile has no data element
  KPKErrorKdbxKeyDataParsingError, // The XML-data element couldn't be parsed
  KPKErrorUnsupportedDatabaseVersion, // The database version is to high/low
  KPKErrorUnsupportedCipher, // The header specifies a unsupported and/or wrong chipher methed
  KPKErrorUnsupportedKeyDerivation, // The header specifies an unsupported and/or wrong key derivation method
  KPKErrorKeyDerivationFailed, // The key derivation failed
  KPKErrorWrongIVVectorSize, // The header has a wrong size of the IV vector for the specified cipher
  KPKErrorUnsupportedCompressionAlgorithm, // The header specifies an unsupporte and/or wrong compressoing algorithm
  KPKErrorUnsupportedRandomStream, // The header specifies an unsupporte stream or it's corrupted
  KPKErrorPasswordAndOrKeyfileWrong, // Password and or keyfile is wrong
  KPKErrorIntegrityCheckFailed, // The startbytes in the header aren't matching the AES stream-start
  KPKErrorKdbxHeaderHashVerificationFailed, // The header hash does not match the one provieded in the database
  KPKErrorKdbxKeePassFileElementMissing, // the Keepass root element is missing
  KPKErrorKdbxRootElementMissing, // The root Elemetn is missing;
  KPKErrorKdbxMetaElementMissing, // The root element has no meta entry
  KPKErrorKdbxGroupElementMissing, // no Group element found
  KPKErrorKdbxInvalidHeaderFieldSize, // KDBX Header field size missmatch
  KPKErrorKdbxInvalidHeaderFieldType, // KDBX Header field type unknown
  KPKErrorKdbxInvalidKeyDerivationData, // The key derivation header data is invalid
  KPKErrorKdbxCorrutpedPublicCustomData, // The custom data stored in the header is corrupted
  KPKErrorKdbxCorruptedEncryptionStream, // The encrypted data was corrupted (KDBX4)
  KPKErrorKdbxCorruptedContentStream, // The content data was corrupted (KDBX3.1)
  KPKErrorKdbxCorruptedInnerHeader, // the inner header is corrupted
  KPKErrorKdbxInvalidInnerHeaderFieldType, // invalid field type in the inner header
  KPKErrorKdbHeaderTruncated, // The header (and thus the file) was truncated
  KPKErrorKdbInvalidFieldType, // KDB Invalid field type
  KPKErrorKdbInvalidFieldSize, // KDB Invalid field size
  KPKErrorKdbCorruptTree, // Tree sturcture is corrupted
  KPKErrorKdbxMalformedXmlStructure, // KDBX XML file has malformed structure
  KPKErrorAttributeKeyValidationFailed, // Validation of attribute key failed
  KPKErrorWindowTitleFormatValidationFailed, // The Window title for autotype is not supported
  KPKErrorNoKeyData // The key file does not contain any data
};

#endif
