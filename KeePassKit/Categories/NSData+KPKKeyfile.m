//
//  NSData+Keyfile.m
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

#import <CommonCrypto/CommonCrypto.h>
#import <KissXML/KissXML.h>

#import "NSData+KPKKeyfile.h"

#import "KPKErrors.h"
#import "KPKFormat.h"

#import "NSString+KPKHexdata.h"
#import "NSData+KPKRandom.h"
#import "NSData+CommonCrypto.h"

NSUInteger const KPKKeyFileTypeXMLv2HashDataSize  = 4;
NSUInteger const KPKKeyFileDataLength             = 32;

@implementation NSData (KPKKeyfile)

+ (NSData *)kpk_keyDataForData:(NSData *)data version:(KPKDatabaseFormat)version error:(NSError *__autoreleasing *)error {
  if(!data) {
    KPKCreateError(error, KPKErrorNoKeyData);
    return nil;
  }
  switch (version) {
    case KPKDatabaseFormatKdb:
      return [self _kpk_dataVersion1ForData:data error:error];
    case KPKDatabaseFormatKdbx:
      return [self _kpk_dataVersion2ForData:data error:error];
    default:
      return nil;
  }
}

+ (NSData *)kpk_keyDataWithContentsOfFile:(NSURL *)url version:(KPKDatabaseFormat)version error:(NSError *__autoreleasing *)error {
  NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
  if(!data) {
    return nil;
  }
  return [self kpk_keyDataForData:data version:version error:error];
}

+ (NSData *)kpk_generateKeyfileDataOfType:(KPKKeyFileType)type {
  NSData *data = [NSData kpk_dataWithRandomBytes:KPKKeyFileDataLength];
  switch(type) {
    case KPKKeyFileTypeBinary:
      return data;
    case KPKKeyFileTypeHex:
      return [[NSString kpk_hexstringFromData:data] dataUsingEncoding:NSUTF8StringEncoding];
    case KPKKeyFileTypeXMLVersion1:
      return [self _kpk_xmlKeyForData:data addHash:NO];
    case KPKKeyFileTypeXMLVersion2:
      return [self _kpk_xmlKeyForData:data addHash:YES];
    default:
      return nil;
  }
}

+ (NSData *)_kpk_xmlKeyForData:(NSData *)data addHash:(BOOL)addHash {
  NSString *xmlString = [NSString stringWithFormat:@"<%@></%@>", kKPKXmlKeyFile, kKPKXmlKeyFile];
  NSError *error;
  
  DDXMLDocument *keyFileDocument = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:&error];
  DDXMLElement *metaElement = [[DDXMLElement alloc] initWithName:kKPKXmlMeta];
  DDXMLElement *keyElement = [[DDXMLElement alloc] initWithName:kKPKXmlKey];
  DDXMLElement *versionElement = [[DDXMLElement alloc] initWithName:kKPKXmlVersion];
  DDXMLElement *dataElement = [[DDXMLElement alloc] initWithName:kKPKXmlData];
  
  [keyFileDocument.rootElement addChild:metaElement];
  [metaElement addChild:versionElement];
  [keyFileDocument.rootElement addChild:keyElement];
  [keyElement addChild:dataElement];
  
  if(addHash) {
    NSData *hashData = [data.SHA256Hash subdataWithRange:NSMakeRange(0, KPKKeyFileTypeXMLv2HashDataSize)];
    NSString *hashHex = [NSString kpk_hexstringFromData:hashData];
    NSString *dataHex = [NSString kpk_hexstringFromData:data];
    
    [versionElement setStringValue:@"2.00"];
    [dataElement setStringValue:dataHex];
    [dataElement addAttributeWithName:kKPKXmlHash stringValue:hashHex];
  }
  else {
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    [versionElement setStringValue:@"1.00"];
    [dataElement setStringValue:base64String];
  }
  return [keyFileDocument XMLDataWithOptions:DDXMLNodePrettyPrint];
  
}

+ (NSData *)_kpk_dataVersion1ForData:(NSData *)data error:(NSError *__autoreleasing *)error {
  if(!data) {
    return nil;
  }
  if(data.length == KPKKeyFileDataLength) {
    return data; // Loading of a 32 bit binary file succeded;
  }
  NSData *decordedData = nil;
  if (data.length == KPKKeyFileDataLength * 2) {
    decordedData = [self _kpk_keyDataFromHex:data];
  }
  /* Hexdata loading failed, so just hash the key */
  if(!decordedData) {
    decordedData = [self _kpk_keyDataFromHash:data];
  }
  return decordedData;
}

+ (NSData *)_kpk_dataVersion2ForData:(NSData *)data error:(NSError *__autoreleasing *)error {
  NSError *internError;
  NSData *keyData = [self _kpk_dataWithForXMLKeyData:data error:&internError];
  if(error) {
    *error = internError;
  }
  if(keyData) {
    return keyData;
  }
  /* if the key file was no XML file, try to load legacy key */
  if(internError.code == KPKErrorNoXmlData) {
    return [self _kpk_dataVersion1ForData:data error:error];
  }
  return nil;
}

+ (NSData *)_kpk_dataWithForXMLKeyData:(NSData *)xmlData error:(NSError *__autoreleasing *)error {
  /*
   Format of the Keyfile
   
   <!-- Version 1.00 -->
   
   <KeyFile>
     <Meta>
       <Version>1.00</Version>
     </Meta>
     <Key>
       <Data>
         KeyData  <!-- Base64 encoded key data -->
       </Data>
     </Key>
   </KeyFile>
   
   <!-- Version 2.00 -->
   
   <KeyFile>
     <Meta>
       <Version>2.00</Version>
     </Meta>
     <Key>
       <Data Hash="HashData" > <!-- Hex encoded hash data. Hash data are the first 4 bytes of Sha256 of key data -->
         keyData               <!-- Hex encoded key data. -->
       </Data>
     </Key>
   </KeyFile>
   
   */
  if(!xmlData) {
    KPKCreateError(error, KPKErrorNoKeyData);
    return nil;
  }
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:error];
  if(document == nil) {
    KPKCreateError(error, KPKErrorNoXmlData);
    return nil;
  }
  
  KPKKeyFileType keyType = KPKKeyFileTypeUnkown;
  
  // Get the root document element
  DDXMLElement *rootElement = [document rootElement];
  if(!rootElement) {
    KPKCreateError(error, KPKErrorKdbxKeyKeyFileElementMissing);
    return nil;
  }
  DDXMLElement *metaElement = [rootElement elementForName:kKPKXmlMeta];
  if(metaElement) {
    NSDictionary *versionMap =  @{ @"1"     : @(KPKKeyFileTypeXMLVersion1),
                                   @"1.0"   : @(KPKKeyFileTypeXMLVersion1),
                                   @"1.00"  : @(KPKKeyFileTypeXMLVersion1),
                                   @"2"     : @(KPKKeyFileTypeXMLVersion2),
                                   @"2.0"   : @(KPKKeyFileTypeXMLVersion2),
                                   @"2.00"  : @(KPKKeyFileTypeXMLVersion2) };
    
    DDXMLElement *versionElement = [metaElement elementForName:kKPKXmlVersion];
    if(!versionElement) {
      KPKCreateError(error, KPKErrorKdbxKeyVersionElementMissing);
      return nil;
    }
    NSString *versionValue = versionElement.stringValue;
    NSNumber *fileTypeValue = versionMap[versionValue];
    
    if(!fileTypeValue) {
      KPKCreateError(error, KPKErrorKdbxKeyUnsupportedVersion);
      return nil;
    }
    
    keyType = (KPKKeyFileType)fileTypeValue.intValue;
  }
  else {
    KPKCreateError(error, 0);
    return nil;
  }
    
  DDXMLElement *keyElement = [rootElement elementForName:kKPKXmlKey];
  if(keyElement == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyKeyElementMissing);
    return nil;
  }
  
  DDXMLElement *dataElement = [keyElement elementForName:kKPKXmlData];
  if(dataElement == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyDataElementMissing);
    return nil;
    
  }
  
  NSString *hashValue = [dataElement attributeForName:kKPKXmlHash].stringValue;
  NSString *trimmedValue = [dataElement.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  NSString *dataValue = [[trimmedValue componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
  
  if(dataValue == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyDataParsingError);
    return nil;
  }
  
  /* Version 1.0 */
  if(keyType == KPKKeyFileTypeXMLVersion1) {
    NSData *keyData = [[NSData alloc] initWithBase64EncodedString:dataValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if(!keyData) {
      KPKCreateError(error, KPKErrorKdbxKeyDataParsingError);
    }
    return keyData;
  }
  
  /* Version 2.0 */
  if(keyType == KPKKeyFileTypeXMLVersion2) {
    NSData *keyData = dataValue.kpk_dataFromHexString;
    NSData *hashData = hashValue.kpk_dataFromHexString;
    if(hashData.length == 0) {
      KPKCreateError(error, KPKErrorKdbxKeyHashAttributeMissing);
      return nil;
    }
    if(hashData.length != 4) {
      KPKCreateError(error, KPKErrorKdbxKeyHashAttributeWrongSize);
      return nil;
    }
    NSData *actualHashData = [keyData.SHA256Hash subdataWithRange:NSMakeRange(0, 4)];
    if([actualHashData isEqualToData:hashData]) {
      return keyData;
    }
    
    KPKCreateError(error, KPKErrorKdbxKeyDataCorrupted);
    return nil;
  }
  
  NSAssert(NO, @"Internal inconsitency while loading XML key file");
  return nil;
}

+ (NSData *)_kpk_keyDataFromHex:(NSData *)hexData {
  NSString *hexString = [[NSString alloc] initWithData:hexData encoding:NSUTF8StringEncoding];
  if(!hexString) {
    return nil;
  }
  if(hexString.length != 64) {
    return nil; // No valid lenght found
  }
  return [hexString kpk_dataFromHexString];
}

+ (NSData *)_kpk_keyDataFromHash:(NSData *)fileData {
  uint8_t buffer[32];
  NSData *chunk;
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  @autoreleasepool {
    const NSUInteger chunkSize = 2048;
    for(NSUInteger iIndex = 0; iIndex < fileData.length; iIndex += chunkSize) {
      NSUInteger maxChunkLenght = MIN(fileData.length - iIndex, chunkSize);
      chunk = [fileData subdataWithRange:NSMakeRange(iIndex, maxChunkLenght)];
      CC_SHA256_Update(&ctx, chunk.bytes, (CC_LONG)chunk.length);
    }
  }
  CC_SHA256_Final(buffer, &ctx);
  
  return [NSData dataWithBytes:buffer length:32];
}



@end
