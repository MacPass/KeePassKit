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
             @(KPKErrorAESDecryptionFailed)               : @"ERROR_AES_DECRYPTION_FAILED",
             @(KPKErrorAESEncryptionFailed)               : @"ERROR_ENCRYPTION_FAILED",
             @(KPKErrorAttributeKeyValidationFailed)      : @"ERROR_ATTRIBUTE_KEY_VALIDATION_FAILED",
             @(KPKErrorDecryptionFailed)                  : @"ERROR_DECRYPTION_FAILED",
             @(KPKErrorIntegrityCheckFailed)              : @"ERROR_INTEGRITY_CHECK_FAILED",
             @(KPKErrorKdbCorruptTree)                    : @"ERROR_KDB_CORRUPT_TREE",
             @(KPKErrorKdbHeaderTruncated)                : @"ERROR_KDB_FILE_HEADER_TRUNCATED",
             @(KPKErrorKdbInvalidFieldSize)               : @"ERROR_INVALID_FIELD_SIZE",
             @(KPKErrorKdbInvalidFieldType)               : @"ERROR_INVALID_FIELD_TYPE",
             @(KPKErrorKdbxGroupElementMissing)           : @"ERROR_GROUP_ELEMENT_MISSING",
             @(KPKErrorKdbxHeaderHashVerificationFailed)  : @"ERROR_HEADER_HASH_VERIFICATION_FAILED",
             @(KPKErrorKdbxInvalidHeaderFieldSize)        : @"ERROR_INVALID_HEADER_FIELD_SIZE",
             @(KPKErrorKdbxInvalidHeaderFieldType)        : @"ERROR_INVALID_HEADER_FIELD_TYPE",
             @(KPKErrorKdbxKeePassFileElementMissing)     : @"ERROR_KEEPASSFILE_ELEMENT_MISSING",
             @(KPKErrorKdbxKeyDataElementMissing)         : @"ERROR_XML_KEYFILE_WITHOUT_DATA_ELEMENT",
             @(KPKErrorKdbxKeyDataParsingError)           : @"ERROR_XML_KEYFILE_DATA_PARSING_ERROR",
             @(KPKErrorKdbxKeyKeyElementMissing)          : @"ERROR_XML_KEYFILE_WITHOUT_KEY_ELEMENT",
             @(KPKErrorKdbxKeyUnsupportedVersion)         : @"ERROR_XML_KEYFILE_UNSUPPORTED_VERSION",
             @(KPKErrorKdbxMetaElementMissing)            : @"ERROR_META_ELEMENT_MISSING",
             @(KPKErrorKdbxRootElementMissing)            : @"ERROR_ROOT_ELEMENT_MISSING",
             @(KPKErrorKeyDerivationFailed)               : @"ERROR_KEY_DERIVATION_FAILED",
             @(KPKErrorNoData)                            : @"ERROR_NO_DATA",
             @(KPKErrorPasswordAndOrKeyfileWrong)         : @"ERROR_PASSWORD_OR_KEYFILE_WRONG",
             @(KPKErrorUnknownFileFormat)                 : @"ERROR_UNKNOWN_FILE_FORMAT",
             @(KPKErrorUnsupportedCipher)                 : @"ERROR_UNSUPPORTED_CIPHER",
             @(KPKErrorUnsupportedCompressionAlgorithm)   : @"ERROR_UNSUPPORTED_KDBX_COMPRESSION_ALGORITHM",
             @(KPKErrorUnsupportedDatabaseVersion)        : @"ERROR_UNSUPPORTED_DATABASER_VERSION",
             @(KPKErrorUnsupportedKeyDerivation)          : @"ERROR_UNSUPPORTED_KEYDERIVATION",
             @(KPKErrorUnsupportedRandomStream)           : @"ERROR_UNSUPPORTED_KDBX_RANDOM_STREAM",
             @(KPKErrorWindowTitleFormatValidationFailed) : @"ERROR_WINDOW_TITLE_VALIDATION_FAILED",
             @(KPKErrorWrongIVVectorSize)                 : @"ERROR_INVALID_HEADER_IV_SIZE"
             };
  });
  NSString *msg = dict[@(errorCode)];
  return msg ? msg : @"ERROR_UNKNOWN_ERROR_CODE";
}

void KPKCreateError( NSError **errorPtr, NSInteger errorCode) {
  if(errorPtr == NULL) {
    return; // no valid error pointer
  }
  *errorPtr = [NSError errorWithDomain:KPKErrorDomain code:errorCode userInfo:@{ NSLocalizedDescriptionKey:NSLocalizedStringFromTable(KPKErrorMessageForCode(errorCode), @"KPKLocalizable", "")}];
}
