//
//  KPKXmlDataCryptor.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTreeCryptor.h"

@interface KPKXmlTreeCryptor : KPKTreeCryptor

- (id)initWithData:(NSData *)data password:(KPKPassword *)password;

@end
