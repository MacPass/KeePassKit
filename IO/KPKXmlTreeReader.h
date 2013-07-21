//
//  KPXmlTreeReader.h
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KPKTree;
@class KPKXmlCipherInformation;

@interface KPKXmlTreeReader : NSObject

/**
 Inilializes the XML Reader with the raw xml data and the random stream
 used to protect containing string fields
 @param data The raw XML data. Make sure to decrypt the data before passing it in
 @param cipherInformation Chipher information to handle the writing
 */
- (id)initWithData:(NSData *)data cipherInformation:(KPKXmlCipherInformation *)cipher;
/**
 @returns
 */
- (KPKTree *)tree;

@end
