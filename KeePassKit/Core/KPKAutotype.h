//
//  KPKAutotype.h
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
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

NS_ASSUME_NONNULL_BEGIN

@class KPKEntry;
@class KPKWindowAssociation;

@interface KPKAutotype : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL obfuscateDataTransfer;
@property (null_resettable, nonatomic, copy) NSString *defaultKeystrokeSequence;
@property (nonnull, nonatomic, strong, readonly) NSArray<KPKWindowAssociation *> *associations;
@property (nonatomic, readonly) BOOL hasDefaultKeystrokeSequence;

@property (nullable, weak, readonly) KPKEntry *entry;

- (instancetype)initWithNotes:(NSString *)notes;

- (BOOL)isEqualToAutotype:(KPKAutotype *)autotype;

- (void)addAssociation:(KPKWindowAssociation *)association;
- (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index;
- (void)removeAssociation:(KPKWindowAssociation *)association;
/**
 *  Searches for a window association, that matches the given window title.
 *  
 *  @param windowTitle The window title to search associations for
 *  @return first matching association, if there are found more, only the first match is returned
 */
- (NSArray<KPKWindowAssociation *> *)windowAssociationsMatchingWindowTitle:(NSString *)windowTitle;

@end

NS_ASSUME_NONNULL_END
