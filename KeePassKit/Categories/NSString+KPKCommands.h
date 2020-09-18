//
//  NSString+Commands.h
//  MacPass
//
//  Created by Michael Starke on 10/11/13.
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
#import <KeePassKit/KPKCommandEvaluationContext.h>

@class KPKEntry;

@interface NSString (KPKAutotype)

/**
 *  Normalizes the Autotype sequence by using only the long-format for all Entries.
 *  @note The sequence is not in valid Keepass format, as curly braches are substitudet and modifier keys are mapped to custom commands
 *
 *  @return NSString with all sequences normalized to internal state
 */
@property (nonatomic, readonly, copy) NSString *kpk_normalizedAutotypeSequence;
/**
 *  Determines if the command is valid. Currently is only bracket-missmatch aware.
 *
 *  @return YES, if the command is valid, NO otherweise.
 */
@property (nonatomic, readonly) BOOL kpk_validCommand;

@end

@interface NSString (KPKEvaluation)

@property (nonatomic, readonly) BOOL kpk_hasReference;

- (NSString *)kpk_finalValueForEntry:(KPKEntry *)entry;
- (NSString *)kpk_finalValueForEntry:(KPKEntry *)entry options:(KPKCommandEvaluationOptions)options;

@end
