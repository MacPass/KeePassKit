//
//  KeePassKit.h
//  KeePassKit
//
//  Created by Michael Starke on 28/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

@import Cocoa;

//! Project version number for KeePassKit.
FOUNDATION_EXPORT double KeePassKitVersionNumber;

//! Project version string for KeePassKit.
FOUNDATION_EXPORT const unsigned char KeePassKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <KeePassKit/PublicHeader.h>

#import "KPKTypes.h"
#import "KPKUTIs.h"
#import "KPKIconTypes.h"

#import "KPKNumber.h"

#import "KPKFormat.h"
#import "KPKKdbxFormat.h"
#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"
#import "KPKArgon2KeyDerivation.h"
#import "KPKCompositeKey.h"

#import "KPKTree.h"
#import "KPKTree+Serializing.h"
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

#import "NSColor+KeePassKit.h"
#import "NSData+HashedData.h"
#import "NSData+Keyfile.h"
#import "NSData+Random.h"
#import "NSDictionary+KPKVariant.h"
#import "NSString+Commands.h"
#import "NSString+Empty.h"
#import "NSString+XMLUtilities.h"
#import "NSUUID+KeePassKit.h"

