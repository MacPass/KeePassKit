//
//  KPKIcon.h
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

@import Foundation;
#import <KeePassKit/KPKPlatformIncludes.h>

@interface KPKIcon : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, strong) NSUUID *uuid;
@property (nonatomic, readonly, strong) NSUIImage *image;
@property (nonatomic, readonly) NSString *encodedString;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly, copy) NSDate *modificationDate;

- (instancetype)initWithImageAtURL:(NSURL *)imageLocation;
- (instancetype)initWithUUID:(NSUUID *)uuid encodedString:(NSString *)encodedString;
- (instancetype)initWithUUID:(NSUUID *)uuid imageData:(NSData *)data;
- (instancetype)initWithImageData:(NSData *)data;
- (instancetype)initWithImage:(NSUIImage *)image;

- (BOOL)isEqualToIcon:(KPKIcon *)icon;

@end
