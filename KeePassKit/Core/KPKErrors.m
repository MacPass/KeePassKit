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

NSString *const KPKErrorDomain = @"com.hicknhack.keepasskit";


NSString *KPKErrorMessageForCode(NSInteger errorCode) {
  static NSDictionary *dict;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dict = @{
             @(KPKErrorAESDecryptionFailed)               : NSLocalizedString(@"ERROR_AES_DECRYPTION_FAILED",@""),
             @(KPKErrorAESEncryptionFailed)               : NSLocalizedString(@"ERROR_ENCRYPTION_FAILED",@""),
             @(KPKErrorAttributeKeyValidationFailed)      : NSLocalizedString(@"ERROR_ATTRIBUTE_KEY_VALIDATION_FAILED",@""),
             @(KPKErrorDecryptionFailed)                  : NSLocalizedString(@"ERROR_DECRYPTION_FAILED",@""),
             @(KPKErrorIntegrityCheckFailed)              : NSLocalizedString(@"ERROR_INTEGRITY_CHECK_FAILED",@""),
             @(KPKErrorKdbCorruptTree)                    : NSLocalizedString(@"ERROR_KDB_CORRUPT_TREE",@""),
             @(KPKErrorKdbHeaderTruncated)                : NSLocalizedString(@"ERROR_KDB_FILE_HEADER_TRUNCATED",@""),
             @(KPKErrorKdbInvalidFieldSize)               : NSLocalizedString(@"ERROR_INVALID_FIELD_SIZE",@""),
             @(KPKErrorKdbInvalidFieldType)               : NSLocalizedString(@"ERROR_INVALID_FIELD_TYPE",@""),
             @(KPKErrorKdbxGroupElementMissing)           : NSLocalizedString(@"ERROR_GROUP_ELEMENT_MISSING",@""),
             @(KPKErrorKdbxHeaderHashVerificationFailed)  : NSLocalizedString(@"ERROR_HEADER_HASH_VERIFICATION_FAILED",@""),
             @(KPKErrorKdbxInvalidHeaderFieldSize)        : NSLocalizedString(@"ERROR_INVALID_HEADER_FIELD_SIZE",@""),
             @(KPKErrorKdbxInvalidHeaderFieldType)        : NSLocalizedString(@"ERROR_INVALID_HEADER_FIELD_TYPE",@""),
             @(KPKErrorKdbxKeePassFileElementMissing)     : NSLocalizedString(@"ERROR_KEEPASSFILE_ELEMENT_MISSING",@""),
             @(KPKErrorKdbxKeyDataElementMissing)         : NSLocalizedString(@"ERROR_XML_KEYFILE_WITHOUT_DATA_ELEMENT",@""),
             @(KPKErrorKdbxKeyDataParsingError)           : NSLocalizedString(@"ERROR_XML_KEYFILE_DATA_PARSING_ERROR",@""),
             @(KPKErrorKdbxKeyKeyElementMissing)          : NSLocalizedString(@"ERROR_XML_KEYFILE_WITHOUT_KEY_ELEMENT",@""),
             @(KPKErrorKdbxKeyUnsupportedVersion)         : NSLocalizedString(@"ERROR_XML_KEYFILE_UNSUPPORTED_VERSION",@""),
             @(KPKErrorKdbxMetaElementMissing)            : NSLocalizedString(@"ERROR_META_ELEMENT_MISSING",@""),
             @(KPKErrorKdbxRootElementMissing)            : NSLocalizedString(@"ERROR_ROOT_ELEMENT_MISSING",@""),
             @(KPKErrorKdbxMalformedXmlStructure)         : NSLocalizedString(@"ERRROR_XML_STRUCUTRE_MALFORMED",@""),
             @(KPKErrorKeyDerivationFailed)               : NSLocalizedString(@"ERROR_KEY_DERIVATION_FAILED",@""),
             @(KPKErrorNoData)                            : NSLocalizedString(@"ERROR_NO_DATA",@""),
             @(KPKErrorPasswordAndOrKeyfileWrong)         : NSLocalizedString(@"ERROR_PASSWORD_OR_KEYFILE_WRONG",@""),
             @(KPKErrorUnknownFileFormat)                 : NSLocalizedString(@"ERROR_UNKNOWN_FILE_FORMAT",@""),
             @(KPKErrorUnsupportedCipher)                 : NSLocalizedString(@"ERROR_UNSUPPORTED_CIPHER",@""),
             @(KPKErrorUnsupportedCompressionAlgorithm)   : NSLocalizedString(@"ERROR_UNSUPPORTED_KDBX_COMPRESSION_ALGORITHM",@""),
             @(KPKErrorUnsupportedDatabaseVersion)        : NSLocalizedString(@"ERROR_UNSUPPORTED_DATABASER_VERSION",@""),
             @(KPKErrorUnsupportedKeyDerivation)          : NSLocalizedString(@"ERROR_UNSUPPORTED_KEYDERIVATION",@""),
             @(KPKErrorUnsupportedRandomStream)           : NSLocalizedString(@"ERROR_UNSUPPORTED_KDBX_RANDOM_STREAM",@""),
             @(KPKErrorWindowTitleFormatValidationFailed) : NSLocalizedString(@"ERROR_WINDOW_TITLE_VALIDATION_FAILED",@""),
             @(KPKErrorWrongIVVectorSize)                 : NSLocalizedString(@"ERROR_INVALID_HEADER_IV_SIZE",@"")
             };
  });
  NSString *msg = dict[@(errorCode)];
  return msg ? msg : NSLocalizedString(@"ERROR_UNKNOWN_ERROR_CODE", @"Error message for unknown error code");
}

void KPKCreateError( NSError **errorPtr, NSInteger errorCode) {
  if(errorPtr == NULL) {
    return; // no valid error pointer
  }
  *errorPtr = [NSError errorWithDomain:KPKErrorDomain code:errorCode userInfo:@{ NSLocalizedDescriptionKey: KPKErrorMessageForCode(errorCode) }];
}
