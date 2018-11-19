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

+ (NSData *)kpk_generateKeyfileDataForFormat:(KPKDatabaseFormat)format {
  NSData *data = [NSData kpk_dataWithRandomBytes:32];
  switch(format) {
    case KPKDatabaseFormatKdb:
      return [[NSString kpk_hexstringFromData:data] dataUsingEncoding:NSUTF8StringEncoding];
      
    case KPKDatabaseFormatKdbx:
      return [self _kpk_xmlKeyForData:data];
    
    default:
      return nil;
  }
}

+ (NSData *)_kpk_xmlKeyForData:(NSData *)data {
  NSString *dataString = [data base64EncodedStringWithOptions:0];
  NSString *xmlString = [NSString stringWithFormat:@"<KeyFile><Meta><Version>1.00</Version></Meta><Key><Data>%@</Data></Key></KeyFile>", dataString];
  DDXMLDocument *keyDocument = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:NULL];
  return [keyDocument XMLDataWithOptions:DDXMLNodePrettyPrint];
}

+ (NSData *)_kpk_dataVersion1ForData:(NSData *)data error:(NSError *__autoreleasing *)error {
  if(!data) {
    return nil;
  }
  if(data.length == 32) {
    return data; // Loading of a 32 bit binary file succeded;
  }
  NSData *decordedData = nil;
  if (data.length == 64) {
    decordedData = [self _kpk_keyDataFromHex:data];
  }
  /* Hexdata loading failed, so just hash the key */
  if(!decordedData) {
    decordedData = [self _kpk_keyDataFromHash:data];
  }
  return decordedData;
}

+ (NSData *)_kpk_dataVersion2ForData:(NSData *)data error:(NSError *__autoreleasing *)error {
  // Try and load a 2.x XML keyfile first
  NSData *keyData = [self _kpk_dataWithForXMLKeyData:data error:error];
  if(!keyData) {
    return [self _kpk_dataVersion1ForData:data error:error];
  }
  return keyData;
}

+ (NSData *)_kpk_dataWithForXMLKeyData:(NSData *)xmlData error:(NSError *__autoreleasing *)error {
  /*
   Format of the Keyfile
   <KeyFile>
   <Meta>
   <Version>1.00</Version>
   </Meta>
   <Key>
   <Data>L8JyIjlAd3SowrQPm6ZaR9mMolm/7iL6T1GJRGBNrAE=</Data>
   </Key>
   </KeyFile>
   */
  if(!xmlData) {
    KPKCreateError(error, KPKErrorNoKeyData);
    return nil;
  }
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:error];
  if (document == nil) {
    return nil;
  }
  
  // Get the root document element
  DDXMLElement *rootElement = [document rootElement];
  
  DDXMLElement *metaElement = [rootElement elementForName:kKPKXmlMeta];
  if(metaElement) {
    DDXMLElement *versionElement = [metaElement elementForName:kKPKXmlVersion];
    NSScanner *versionScanner = [[NSScanner alloc] initWithString:[versionElement stringValue]];
    double version = 1;
    if(![versionScanner scanDouble:&version] || version > 1) {
      KPKCreateError(error, KPKErrorKdbxKeyUnsupportedVersion);
      return nil;
    }
  }
  
  DDXMLElement *keyElement = [rootElement elementForName:kKPKXmlKey];
  if (keyElement == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyKeyElementMissing);
    return nil;
  }
  
  DDXMLElement *dataElement = [keyElement elementForName:kKPKXmlData];
  if (dataElement == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyDataElementMissing);
    return nil;
    
  }
  
  NSString *dataString = [dataElement stringValue];
  if (dataString == nil) {
    KPKCreateError(error, KPKErrorKdbxKeyDataParsingError);
    return nil;
  }

  return [[NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
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
