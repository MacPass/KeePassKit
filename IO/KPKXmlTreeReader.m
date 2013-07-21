//
//  KPXmlTreeReader.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlTreeReader.h"
#import "DDXMLDocument.h"

#import "RandomStream.h"
#import "Arc4RandomStream.h"
#import "Salsa20RandomStream.h"

@interface KPKXmlTreeReader () {
  @private
  DDXMLDocument *_document;
  KPKXmlCipherInformation *_cipherInfo;
}
@end

@implementation KPKXmlTreeReader

- (id)initWithData:(NSData *)data cipherInformation:(KPKXmlCipherInformation *)cipher {
  self = [super init];
  if(self) {
    _document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    _cipherInfo = cipher;
  }
  return self;
}

- (KPKTree *)tree {
  //DDXMLElement *rootElement = [_document rootElement];
  return nil;
}

@end
