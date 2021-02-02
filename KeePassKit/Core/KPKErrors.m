//
//  KPKErrors.m
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

#import "KPKErrors.h"
#import "KPKPair.h"

NSString *const KPKErrorDomain = @"com.hicknhack.keepasskit";


NSString *KPKErrorMessageForCode(NSInteger errorCode) {
  static NSDictionary *dict;
  static dispatch_once_t onceToken;
  NSBundle *bundle = [NSBundle bundleForClass:KPKPair.class];
  dispatch_once(&onceToken, ^{
    dict = @{
      @(KPKErrorAESDecryptionFailed)               : NSLocalizedStringFromTableInBundle(@"ERROR_AES_DECRYPTION_FAILED", nil, bundle, @""),
      @(KPKErrorAESEncryptionFailed)               : NSLocalizedStringFromTableInBundle(@"ERROR_AES_ENCRYPTION_FAILED", nil, bundle, @""),
      @(KPKErrorAttributeKeyValidationFailed)      : NSLocalizedStringFromTableInBundle(@"ERROR_ATTRIBUTE_KEY_VALIDATION_FAILED", nil, bundle, @""),
      @(KPKErrorDecryptionFailed)                  : NSLocalizedStringFromTableInBundle(@"ERROR_DECRYPTION_FAILED", nil, bundle, @""),
      @(KPKErrorEncryptionFailed)                  : NSLocalizedStringFromTableInBundle(@"ERROR_ENCRYPTION_FAILED", nil, bundle, @""),
      @(KPKErrorIntegrityCheckFailed)              : NSLocalizedStringFromTableInBundle(@"ERROR_INTEGRITY_CHECK_FAILED", nil, bundle, @""),
      @(KPKErrorKdbCorruptTree)                    : NSLocalizedStringFromTableInBundle(@"ERROR_KDB_CORRUPT_TREE", nil, bundle, @""),
      @(KPKErrorKdbHeaderTruncated)                : NSLocalizedStringFromTableInBundle(@"ERROR_KDB_FILE_HEADER_TRUNCATED", nil, bundle, @""),
      @(KPKErrorKdbInvalidFieldSize)               : NSLocalizedStringFromTableInBundle(@"ERROR_INVALID_FIELD_SIZE", nil, bundle, @""),
      @(KPKErrorKdbInvalidFieldType)               : NSLocalizedStringFromTableInBundle(@"ERROR_INVALID_FIELD_TYPE", nil, bundle, @""),
      @(KPKErrorKdbxCorruptedContentStream)        : NSLocalizedStringFromTableInBundle(@"ERROR_KDBX_CORRUPTED_CONTENT_STREAM", nil, bundle, @""),
      @(KPKErrorKdbxCorruptedEncryptionStream)     : NSLocalizedStringFromTableInBundle(@"ERROR_KDBX_CORRUPTED_ENCRYPTION_STREAM", nil, bundle, @""),
      @(KPKErrorKdbxCorruptedInnerHeader)          : NSLocalizedStringFromTableInBundle(@"ERROR_KDBX_CORRUPTED_INNER_HEADER", nil, bundle, @""),
      @(KPKErrorKdbxCorrutpedPublicCustomData)     : NSLocalizedStringFromTableInBundle(@"ERROR_KDBX_CORRUPTED_PUBLIC_CUSTOM_DATA", nil, bundle, @""),
      @(KPKErrorKdbxGroupElementMissing)           : NSLocalizedStringFromTableInBundle(@"ERROR_GROUP_ELEMENT_MISSING", nil, bundle, @""),
      @(KPKErrorKdbxHeaderHashVerificationFailed)  : NSLocalizedStringFromTableInBundle(@"ERROR_HEADER_HASH_VERIFICATION_FAILED", nil, bundle, @""),
      @(KPKErrorKdbxInvalidHeaderFieldSize)        : NSLocalizedStringFromTableInBundle(@"ERROR_INVALID_HEADER_FIELD_SIZE", nil, bundle, @""),
      @(KPKErrorKdbxInvalidHeaderFieldType)        : NSLocalizedStringFromTableInBundle(@"ERROR_INVALID_HEADER_FIELD_TYPE", nil, bundle, @""),
      @(KPKErrorKdbxInvalidInnerHeaderFieldType)   : NSLocalizedStringFromTableInBundle(@"ERROR_KDBX_INVALID_INNER_HEADER_FIELD", nil, bundle, @""),
      @(KPKErrorKdbxInvalidKeyDerivationData)      : NSLocalizedStringFromTableInBundle(@"ERROR_KDBX_INVALID_KEY_DERIVATION_DATA", nil, bundle, @""),
      @(KPKErrorKdbxKeePassFileElementMissing)     : NSLocalizedStringFromTableInBundle(@"ERROR_KEEPASSFILE_ELEMENT_MISSING", nil, bundle, @""),
      @(KPKErrorKdbxKeyMetaElementMissing)         : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_WITHOUT_META_ELEMENT", nil, bundle, @""),
      @(KPKErrorKdbxKeyKeyFileElementMissing)      : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_WITHOUT_KEYFILE_ELEMENT", nil, bundle, @""),
      @(KPKErrorKdbxKeyHashAttributeMissing)       : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_WITHOUT_HASH_ATTRIBUTE", nil, bundle, @""),
      @(KPKErrorKdbxKeyHashAttributeWrongSize)     : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_WRONG_HASH_SIZE", nil, bundle, @""),
      @(KPKErrorKdbxKeyDataCorrupted)              : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_CORRUPTED", nil, bundle, @""),
      @(KPKErrorKdbxKeyDataElementMissing)         : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_WITHOUT_DATA_ELEMENT", nil, bundle, @""),
      @(KPKErrorKdbxKeyDataParsingError)           : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_DATA_PARSING_ERROR", nil, bundle, @""),
      @(KPKErrorKdbxKeyKeyElementMissing)          : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_WITHOUT_KEY_ELEMENT", nil, bundle, @""),
      @(KPKErrorKdbxKeyUnsupportedVersion)         : NSLocalizedStringFromTableInBundle(@"ERROR_XML_KEYFILE_UNSUPPORTED_VERSION", nil, bundle, @""),
      @(KPKErrorKdbxMalformedXmlStructure)         : NSLocalizedStringFromTableInBundle(@"ERRROR_XML_STRUCUTRE_MALFORMED", nil, bundle, @""),
      @(KPKErrorKdbxMetaElementMissing)            : NSLocalizedStringFromTableInBundle(@"ERROR_META_ELEMENT_MISSING", nil, bundle, @""),
      @(KPKErrorKdbxRootElementMissing)            : NSLocalizedStringFromTableInBundle(@"ERROR_ROOT_ELEMENT_MISSING", nil, bundle, @""),
      @(KPKErrorKeyDerivationFailed)               : NSLocalizedStringFromTableInBundle(@"ERROR_KEY_DERIVATION_FAILED", nil, bundle, @""),
      @(KPKErrorNoData)                            : NSLocalizedStringFromTableInBundle(@"ERROR_NO_DATA", nil, bundle, @""),
      @(KPKErrorNoKeyData)                         : NSLocalizedStringFromTableInBundle(@"ERROR_NO_KEY_DATA", nil, bundle, @""),
      @(KPKErrorNoXmlData)                         : NSLocalizedStringFromTableInBundle(@"ERROR_NO_XML_DATA", nil, bundle, @""),
      @(KPKErrorPasswordAndOrKeyfileWrong)         : NSLocalizedStringFromTableInBundle(@"ERROR_PASSWORD_OR_KEYFILE_WRONG", nil, bundle, @""),
      @(KPKErrorUnknownFileFormat)                 : NSLocalizedStringFromTableInBundle(@"ERROR_UNKNOWN_FILE_FORMAT", nil, bundle, @""),
      @(KPKErrorUnsupportedCipher)                 : NSLocalizedStringFromTableInBundle(@"ERROR_UNSUPPORTED_CIPHER", nil, bundle, @""),
      @(KPKErrorUnsupportedCompressionAlgorithm)   : NSLocalizedStringFromTableInBundle(@"ERROR_UNSUPPORTED_KDBX_COMPRESSION_ALGORITHM", nil, bundle, @""),
      @(KPKErrorUnsupportedDatabaseVersion)        : NSLocalizedStringFromTableInBundle(@"ERROR_UNSUPPORTED_DATABASER_VERSION", nil, bundle, @""),
      @(KPKErrorUnsupportedKeyDerivation)          : NSLocalizedStringFromTableInBundle(@"ERROR_UNSUPPORTED_KEYDERIVATION", nil, bundle, @""),
      @(KPKErrorUnsupportedRandomStream)           : NSLocalizedStringFromTableInBundle(@"ERROR_UNSUPPORTED_KDBX_RANDOM_STREAM", nil, bundle, @""),
      @(KPKErrorWindowTitleFormatValidationFailed) : NSLocalizedStringFromTableInBundle(@"ERROR_WINDOW_TITLE_VALIDATION_FAILED", nil, bundle, @""),
      @(KPKErrorWrongIVVectorSize)                 : NSLocalizedStringFromTableInBundle(@"ERROR_INVALID_HEADER_IV_SIZE", nil, bundle, @"")
    };
  });
  NSString *msg = dict[@(errorCode)];
  return msg ? msg : NSLocalizedStringFromTableInBundle(@"ERROR_UNKNOWN_ERROR_CODE", nil, bundle, @"Error message for unknown error code");
}

void KPKCreateError( NSError * __autoreleasing *errorPtr, NSInteger errorCode) {
  if(errorPtr == NULL) {
    return; // no valid error pointer
  }
  *errorPtr = [NSError errorWithDomain:KPKErrorDomain code:errorCode userInfo:@{ NSLocalizedDescriptionKey: KPKErrorMessageForCode(errorCode) }];
}
