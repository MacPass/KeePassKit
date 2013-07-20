//
//  KPKHeaderFields.h
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#ifndef MacPass_KPKHeaderFields_h
#define MacPass_KPKHeaderFields_h

#import <Foundation/Foundation.h>

/**
 Header keys for KDBX files
 */
typedef NS_ENUM(NSUInteger, KPKHeaderKey ) {
  KPKHeaderKeyEndOfHeader,
  KPKHeaderKeyComment,
  KPKHeaderKeyCipherId,
  KPKHeaderKeyCompression,
  KPKHeaderKeyMasterSeed,
  KPKHeaderKeyTransformSeed,
  KPKHeaderKeyTransformRounds,
  KPKHeaderKeyEncryptionIV,
  KPKHeaderKeyProtectedKey,
  KPKHeaderKeyStartBytes,
  KPKHeaderKeyRandomStreamId
};
#endif
