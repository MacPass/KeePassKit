//
//  KPKLegacyFieldTypes.h
//  KeePassKit
//
//  Created by Michael Starke on 08.08.13.
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

#ifndef MacPass_KPKKdbFormat_h
#define MacPass_KPKKdbFormat_h

#import <Foundation/Foundation.h>

typedef struct {
  uint32_t signature1;
  uint32_t signature2;
  uint32_t flags;
  uint32_t version;
  
  uint8_t masterSeed[16];
  uint8_t encryptionIV[16];
  
  uint32_t groups;
  uint32_t entries;
  
  uint8_t contentsHash[32];
  
  uint8_t transformationSeed[32];
  uint32_t keyEncRounds;
} KPKLegacyHeader;

typedef struct {
  uint32_t uLastSelectedGroupId;
  uint32_t uLastTopVisibleGroupId;
  uint8_t aLastSelectedEntryUuid[16];
  uint8_t aLastTopVisibleEntryUuid[16];
  uint32_t dwReserved01;
  uint32_t dwReserved02;
  uint32_t dwReserved03;
  uint32_t dwReserved04;
  uint32_t dwReserved05;
  uint32_t dwReserved06;
  uint32_t dwReserved07;
  uint32_t dwReserved08;
  uint32_t dwReserved09;
  uint32_t dwReserved10;
  uint32_t dwReserved11;
  uint32_t dwReserved12;
  uint32_t dwReserved13;
  uint32_t dwReserved14;
  uint32_t dwReserved15;
  uint32_t dwReserved16;
} KPKSimpleUiState;

typedef NS_ENUM(NSUInteger, KPKLegacyFieldType) {
  /* Common types */
  KPKFieldTypeCommonHash = 0,
  KPKFieldTypeCommonStop = 0xFFFF,
  /* Groups Types */
  KPKFieldTypeGroupId    = 1,
  KPKFieldTypeGroupName,
  KPKFieldTypeGroupCreationTime,
  KPKFieldTypeGroupModificationTime,
  KPKFieldTypeGroupAccessTime,
  KPKFieldTypeGroupExpiryDate,
  KPKFieldTypeGroupImage,
  KPKFieldTypeGroupLevel,
  KPKFieldTypeGroupFlags,
  /* Entry Types */
  KPKFieldTypeEntryUUID = 1,
  KPKFieldTypeEntryGroupId,
  KPKFieldTypeEntryImage,
  KPKFieldTypeEntryTitle,
  KPKFieldTypeEntryURL,
  KPKFieldTypeEntryUsername,
  KPKFieldTypeEntryPassword,
  KPKFieldTypeEntryNotes,
  KPKFieldTypeEntryCreationTime,
  KPKFieldTypeEntryModificationTime,
  KPKFieldTypeEntryAccessTime,
  KPKFieldTypeEntryExpiryDate,
  KPKFieldTypeEntryBinaryDescription,
  KPKFieldTypeEntryBinaryData,
  /* Header Hash */
  KPKHeaderHashFieldTypeHeaderHash = 1,
  KPKHeaderHashFieldTypeRandomData
};

typedef NS_OPTIONS(NSUInteger, KPKLegacyEncryptionFlags) {
  KPKLegacyEncryptionSHA2       = 1<<0,
  KPKLegacyEncryptionAES        = 1<<1,
  KPKLegacyEncryptionArcFour    = 1<<2,
  KPKLegacyEncryptionTwoFish    = 1<<3
};

#endif
