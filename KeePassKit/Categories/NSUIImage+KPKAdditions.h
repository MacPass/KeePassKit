//
//  NSImage+KPKAdditions.h
//  KeePassKit
//
//  Created by Michael Starke on 14.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKPlatformIncludes.h"

@interface NSUIImage (KPKAdditions)

@property (readonly, copy) NSData *kpk_pngData;

@end
