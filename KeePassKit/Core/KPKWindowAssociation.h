//
//  KPKWindowAssociation.h
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

@class KPKAutotype;

/**
 *  Association for Autotype to a given window title
 */
@interface KPKWindowAssociation : NSObject <NSCopying, NSSecureCoding>

/**
 *  The title of the window for this autotype sequence
 */
@property (nonatomic, copy) NSString *windowTitle;
/**
 *  The autotype sequence to use for this window association
 */
@property (nonatomic, copy) NSString *keystrokeSequence;
@property (weak, readonly) KPKAutotype *autotype;
@property (nonatomic, readonly) BOOL hasDefaultKeystrokeSequence;

- (instancetype)initWithWindowTitle:(NSString *)windowTitle keystrokeSequence:(NSString *)strokes NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToWindowAssociation:(KPKWindowAssociation *)other;

/**
 *  Returns YES if the supplied window title is matched by the association
 *
 *  @param windowTitle the title of the window to test for matching
 *
 *  @return YES on successful match, no otherwise
 */
- (BOOL)matchesWindowTitle:(NSString *)windowTitle;


@end
