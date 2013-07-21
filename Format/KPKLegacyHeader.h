//
//  KPKLegacyHeader.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#ifndef MacPass_KPKLegacyHeader_h
#define MacPass_KPKLegacyHeader_h

typedef struct {
	uint32_t signature1;
	uint32_t signature2;
	uint32_t flags;
	uint32_t version;
  
	uint8_t masterSeed[16];
	uint8_t encryptionIv[16];
  
	uint32_t groups;
	uint32_t entries;
  
	uint8_t contentsHash[32];
  
	uint8_t masterSeed2[32];
	uint32_t keyEncRounds;
} KPKLegacyHeader;

#endif
