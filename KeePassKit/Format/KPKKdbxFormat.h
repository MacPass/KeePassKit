//
//  KPKKdbxFormat.h
//  KeePassKit
//
//  Created by Michael Starke on 20.07.13.
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

#ifndef MacPass_KPKKdbxFormat_h
#define MacPass_KPKKdbxFormat_h

@import Foundation;

/**
 Header keys for KDBX files
 */
typedef NS_ENUM(NSUInteger, KPKHeaderKey ) {
  KPKHeaderKeyEndOfHeader       = 0,
  KPKHeaderKeyComment           = 1,  // Ignored, KDBX3.1 does not use this!
  KPKHeaderKeyCipherId          = 2,
  KPKHeaderKeyCompression       = 3,
  KPKHeaderKeyMasterSeed        = 4,
  KPKHeaderKeyTransformSeed     = 5,  // KDBX 3.1, for backward compatibility only
  KPKHeaderKeyTransformRounds   = 6,  // KDBX 3.1, for backward compatibility only
  KPKHeaderKeyEncryptionIV      = 7,
  KPKHeaderKeyProtectedKey      = 8,
  KPKHeaderKeyStartBytes        = 9,  // KDBX 3.1, for backward compatibility only
  KPKHeaderKeyRandomStreamId    = 10,
  KPKHeaderKeyKdfParameters     = 11, // KDBX 4
  KPKHeaderKeyPublicCustomData  = 12  // KDBX 4
};

typedef NS_ENUM(uint8_t, KPKInnerHeaderKey) {
  KPKInnerHeaderKeyEndOfHeader      = 0,
  KPKInnerHeaderKeyRandomStreamId   = 1,
  KPKInnerHeaderKeyRandomStreamKey  = 2,
  KPKInnerHeaderKeyBinary           = 3
};

typedef NS_OPTIONS(uint8_t, KPKBinaryFlags) {
  KPKBinaryProtectMemoryFlag = 1 << 0
};

typedef NS_ENUM(uint32_t, KPKCompression) {
  KPKCompressionNone,
  KPKCompressionGzip,
  KPKCompressionCount,
};

typedef NS_ENUM(uint32_t, KPKRandomStreamType) {
  KPKRandomStreamNone,
  KPKRandomStreamArc4,
  KPKRandomStreamSalsa20,
  KPKRandomStreamChaCha20,
  KPKRandomStreamCount
};

#endif
