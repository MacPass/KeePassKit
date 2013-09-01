//
//  KPKAttribute.h
//  KeePassKit
//
//  Created by Michael Starke on 15.07.13.
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

@class KPKEntry;

@interface KPKAttribute : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) NSString *value;
@property (nonatomic, assign) BOOL isProtected;
@property (nonatomic, readonly) BOOL isReference;
@property (nonatomic, readonly) BOOL isPlaceholder;
@property (nonatomic, readonly) NSString *referencedValue;
@property (nonatomic, readonly) NSString *placeholderValue;


@property (weak) KPKEntry *entry; /// Reference to entry to be able to validate keys

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value isProtected:(BOOL)protected;
- (instancetype)initWithKey:(NSString *)key value:(NSString *)value;
- (BOOL)isDefault;
- (void)setValueWithoutUndoRegistration:(NSString *)value;

@end
