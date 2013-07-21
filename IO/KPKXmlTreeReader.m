//
//  KPXmlTreeReader.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlTreeReader.h"
#import "DDXMLDocument.h"

@interface KPKXmlTreeReader () {
  @private
  DDXMLDocument *_document;
  RandomStream *_randomStream;
}
@end

@implementation KPKXmlTreeReader

- (id)initWithData:(NSData *)data randomStream:(RandomStream *)randomStream{
  self = [super init];
  if(self) {
    _document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    _randomStream = randomStream;
  }
  return self;
}

- (KPKTree *)tree {
  DDXMLElement *rootElement = [_document rootElement];
  return nil;
}

@end
