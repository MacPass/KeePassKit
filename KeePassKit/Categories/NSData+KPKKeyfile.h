//
//  NSData+Keyfile.h
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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


#import <Foundation/Foundation.h>
#import <KeePassKit/KPKFormat.h>

typedef NS_ENUM(NSUInteger, KPKKeyFileType) {
  KPKKeyFileTypeUnkown,       // Unkown key file type
  KPKKeyFileTypeBinary,      // KDB Binary format (Hex-Key)
  KPKKeyFileTypeHex,      // KDB Binary format (Hex-Key)
  KPKKeyFileTypeXMLVersion1,  // KDBX XML Version 1
  KPKKeyFileTypeXMLVersion2   // KDBX XML Version 2
};

FOUNDATION_EXTERN NSUInteger const KPKKeyFileTypeXMLv2HashDataSize;
FOUNDATION_EXPORT NSUInteger const KPKKeyFileDataLength;

@interface NSData (KPKKeyfile)

+ (NSData *)kpk_keyDataForData:(NSData *)data version:(KPKDatabaseFormat)version error:(NSError *__autoreleasing *)error;
+ (NSData *)kpk_generateKeyfileDataOfType:(KPKKeyFileType)type;

@end
