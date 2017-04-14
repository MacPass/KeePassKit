//
//  KeePassKit.h
//  KeePassKit
//
//  Created by Michael Starke on 28/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef _KEEPASSKIT_
#define _KEEPASSKIT_

#if __has_include(<KeePassKit/KeePassKit.h>)

//! Project version number for KeePassKit.
FOUNDATION_EXPORT double KeePassKitVersionNumber;

//! Project version string for KeePassKit.
FOUNDATION_EXPORT const unsigned char KeePassKitVersionString[];

#import <KeePassKit/KPKTypes.h>
#import <KeePassKit/KPKUTIs.h>
#import <KeePassKit/KPKIconTypes.h>

#import <KeePassKit/KPKData.h>
#import <KeePassKit/KPKNumber.h>

#import <KeePassKit/KPKFormat.h>
#import <KeePassKit/KPKKdbxFormat.h>
#import <KeePassKit/KPKKeyDerivation.h>
#import <KeePassKit/KPKAESKeyDerivation.h>
#import <KeePassKit/KPKArgon2KeyDerivation.h>
#import <KeePassKit/KPKCompositeKey.h>
#import <KeePassKit/KPKCipher.h>
#import <KeePassKit/KPKChaCha20Cipher.h>
#import <KeePassKit/KPKAESCipher.h>
#import <KeePassKit/KPKTwofishCipher.h>

#import <KeePassKit/KPKTree.h>
#import <KeePassKit/KPKTree+Serializing.h>
#import <KeePassKit/KPKTree+Synchronization.h>
#import <KeePassKit/KPKNode.h>
#import <KeePassKit/KPKEntry.h>
#import <KeePassKit/KPKGroup.h>

#import <KeePassKit/KPKBinary.h>
#import <KeePassKit/KPKAttribute.h>
#import <KeePassKit/KPKIcon.h>
#import <KeePassKit/KPKDeletedNode.h>
#import <KeePassKit/KPKMetaData.h>
#import <KeePassKit/KPKTimeInfo.h>
#import <KeePassKit/KPKAutotype.h>
#import <KeePassKit/KPKWindowAssociation.h>

#import <KeePassKit/KPKModificationRecording.h>
#import <KeePassKit/KPKTreeDelegate.h>

#import <KeePassKit/KPKErrors.h>

#import <KeePassKit/NSColor+KPKAdditions.h>
#import <KeePassKit/NSData+KPKHashedData.h>
#import <KeePassKit/NSData+KPKKeyfile.h>
#import <KeePassKit/NSData+KPKRandom.h>
#import <KeePassKit/NSDictionary+KPKVariant.h>
#import <KeePassKit/NSString+KPKCommands.h>
#import <KeePassKit/NSString+KPKEmpty.h>
#import <KeePassKit/NSString+KPKXmlUtilities.h>
#import <KeePassKit/NSUUID+KPKAdditions.h>

#else

#import "KPKTypes.h"
#import "KPKUTIs.h"
#import "KPKIconTypes.h"

#import "KPKData.h"
#import "KPKNumber.h"

#import "KPKFormat.h"
#import "KPKKdbxFormat.h"
#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"
#import "KPKArgon2KeyDerivation.h"
#import "KPKCompositeKey.h"
#import "KPKCipher.h"
#import "KPKChaCha20Cipher.h"
#import "KPKAESCipher.h"
#import "KPKTwofishCipher.h"

#import "KPKTree.h"
#import "KPKTree+Serializing.h"
#import "KPKTree+Synchronization.h"
#import "KPKNode.h"
#import "KPKEntry.h"
#import "KPKGroup.h"

#import "KPKBinary.h"
#import "KPKAttribute.h"
#import "KPKIcon.h"
#import "KPKDeletedNode.h"
#import "KPKMetaData.h"
#import "KPKTimeInfo.h"
#import "KPKAutotype.h"
#import "KPKWindowAssociation.h"

#import "KPKModificationRecording.h"
#import "KPKTreeDelegate.h"

#import "KPKErrors.h"

#import "NSColor+KPKAdditions.h"
#import "NSData+KPKHashedData.h"
#import "NSData+KPKKeyfile.h"
#import "NSData+KPKRandom.h"
#import "NSDictionary+KPKVariant.h"
#import "NSString+KPKCommands.h"
#import "NSString+KPKEmpty.h"
#import "NSString+KPKXmlUtilities.h"
#import "NSUUID+KPKAdditions.h"

#endif

#endif
