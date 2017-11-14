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
#import "KPKGlobalDefines.h"
#import "KPKPair.h"

NSString *const KPKErrorDomain = @"com.hicknhack.keepasskit";


NSString *KPKErrorMessageForCode(NSInteger errorCode) {
  static NSDictionary *dict;
  static dispatch_once_t onceToken;
  NSBundle *bundle = [NSBundle bundleForClass:[KPKPair class]];
  dispatch_once(&onceToken, ^{
    dict = @{
             @(KPKErrorAESDecryptionFailed)               : KPKLocalizedStringInBundle(@"ERROR_AES_DECRYPTION_FAILED", bundle, @""),
             @(KPKErrorAESEncryptionFailed)               : KPKLocalizedStringInBundle(@"ERROR_ENCRYPTION_FAILED", bundle, @""),
             @(KPKErrorAttributeKeyValidationFailed)      : KPKLocalizedStringInBundle(@"ERROR_ATTRIBUTE_KEY_VALIDATION_FAILED", bundle, @""),
             @(KPKErrorDecryptionFailed)                  : KPKLocalizedStringInBundle(@"ERROR_DECRYPTION_FAILED", bundle, @""),
             @(KPKErrorIntegrityCheckFailed)              : KPKLocalizedStringInBundle(@"ERROR_INTEGRITY_CHECK_FAILED", bundle, @""),
             @(KPKErrorKdbCorruptTree)                    : KPKLocalizedStringInBundle(@"ERROR_KDB_CORRUPT_TREE", bundle, @""),
             @(KPKErrorKdbHeaderTruncated)                : KPKLocalizedStringInBundle(@"ERROR_KDB_FILE_HEADER_TRUNCATED", bundle, @""),
             @(KPKErrorKdbInvalidFieldSize)               : KPKLocalizedStringInBundle(@"ERROR_INVALID_FIELD_SIZE", bundle, @""),
             @(KPKErrorKdbInvalidFieldType)               : KPKLocalizedStringInBundle(@"ERROR_INVALID_FIELD_TYPE", bundle, @""),
             @(KPKErrorKdbxGroupElementMissing)           : KPKLocalizedStringInBundle(@"ERROR_GROUP_ELEMENT_MISSING", bundle, @""),
             @(KPKErrorKdbxHeaderHashVerificationFailed)  : KPKLocalizedStringInBundle(@"ERROR_HEADER_HASH_VERIFICATION_FAILED", bundle, @""),
             @(KPKErrorKdbxInvalidHeaderFieldSize)        : KPKLocalizedStringInBundle(@"ERROR_INVALID_HEADER_FIELD_SIZE", bundle, @""),
             @(KPKErrorKdbxInvalidHeaderFieldType)        : KPKLocalizedStringInBundle(@"ERROR_INVALID_HEADER_FIELD_TYPE", bundle, @""),
             @(KPKErrorKdbxKeePassFileElementMissing)     : KPKLocalizedStringInBundle(@"ERROR_KEEPASSFILE_ELEMENT_MISSING", bundle, @""),
             @(KPKErrorKdbxKeyDataElementMissing)         : KPKLocalizedStringInBundle(@"ERROR_XML_KEYFILE_WITHOUT_DATA_ELEMENT", bundle, @""),
             @(KPKErrorKdbxKeyDataParsingError)           : KPKLocalizedStringInBundle(@"ERROR_XML_KEYFILE_DATA_PARSING_ERROR", bundle, @""),
             @(KPKErrorKdbxKeyKeyElementMissing)          : KPKLocalizedStringInBundle(@"ERROR_XML_KEYFILE_WITHOUT_KEY_ELEMENT", bundle, @""),
             @(KPKErrorKdbxKeyUnsupportedVersion)         : KPKLocalizedStringInBundle(@"ERROR_XML_KEYFILE_UNSUPPORTED_VERSION", bundle, @""),
             @(KPKErrorKdbxMetaElementMissing)            : KPKLocalizedStringInBundle(@"ERROR_META_ELEMENT_MISSING", bundle, @""),
             @(KPKErrorKdbxRootElementMissing)            : KPKLocalizedStringInBundle(@"ERROR_ROOT_ELEMENT_MISSING", bundle, @""),
             @(KPKErrorKdbxMalformedXmlStructure)         : KPKLocalizedStringInBundle(@"ERRROR_XML_STRUCUTRE_MALFORMED", bundle, @""),
             @(KPKErrorKeyDerivationFailed)               : KPKLocalizedStringInBundle(@"ERROR_KEY_DERIVATION_FAILED", bundle, @""),
             @(KPKErrorNoData)                            : KPKLocalizedStringInBundle(@"ERROR_NO_DATA", bundle, @""),
             @(KPKErrorPasswordAndOrKeyfileWrong)         : KPKLocalizedStringInBundle(@"ERROR_PASSWORD_OR_KEYFILE_WRONG", bundle, @""),
             @(KPKErrorUnknownFileFormat)                 : KPKLocalizedStringInBundle(@"ERROR_UNKNOWN_FILE_FORMAT", bundle, @""),
             @(KPKErrorUnsupportedCipher)                 : KPKLocalizedStringInBundle(@"ERROR_UNSUPPORTED_CIPHER", bundle, @""),
             @(KPKErrorUnsupportedCompressionAlgorithm)   : KPKLocalizedStringInBundle(@"ERROR_UNSUPPORTED_KDBX_COMPRESSION_ALGORITHM", bundle, @""),
             @(KPKErrorUnsupportedDatabaseVersion)        : KPKLocalizedStringInBundle(@"ERROR_UNSUPPORTED_DATABASER_VERSION", bundle, @""),
             @(KPKErrorUnsupportedKeyDerivation)          : KPKLocalizedStringInBundle(@"ERROR_UNSUPPORTED_KEYDERIVATION", bundle, @""),
             @(KPKErrorUnsupportedRandomStream)           : KPKLocalizedStringInBundle(@"ERROR_UNSUPPORTED_KDBX_RANDOM_STREAM", bundle, @""),
             @(KPKErrorWindowTitleFormatValidationFailed) : KPKLocalizedStringInBundle(@"ERROR_WINDOW_TITLE_VALIDATION_FAILED", bundle, @""),
             @(KPKErrorWrongIVVectorSize)                 : KPKLocalizedStringInBundle(@"ERROR_INVALID_HEADER_IV_SIZE", bundle, @"")
             };
  });
  NSString *msg = dict[@(errorCode)];
  return msg ? msg : KPKLocalizedStringInBundle(@"ERROR_UNKNOWN_ERROR_CODE", bundle, @"Error message for unknown error code");
}

void KPKCreateError( NSError **errorPtr, NSInteger errorCode) {
  if(errorPtr == NULL) {
    return; // no valid error pointer
  }
  *errorPtr = [NSError errorWithDomain:KPKErrorDomain code:errorCode userInfo:@{ NSLocalizedDescriptionKey: KPKErrorMessageForCode(errorCode) }];
}
