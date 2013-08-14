//
//  NSString+KPKCommandString.h
//  KeePassKit
//
//  Created by Michael Starke on 17.07.13.
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

@interface NSString (CommandString)

/**
 @returns YES if the string is enclosed in curly braces {STRING}
 */
- (BOOL)isCommandString;
/**
 @returns YES if the string is a reference String
 */
- (BOOL)isRefernce;
/**
 @returns the selector to be called to look for a matching reference
 */
- (SEL)referenceSelector;
/**
 @returns the predicate to filter the return value by the referenceSelector
 */
- (NSPredicate *)referencePredicate;
/**
 @returns YES if the string is a simple placeholder
 */
- (BOOL)isPlaceholder;
/**
 @returns the value for this placeholderstring, nil if nothing can be found
 */
- (NSString *)placeholderValue;
/**
 *	Evaluates all placeholders inside the string an replaces them with values found in the entry
 *	@param	entry	The enty to use a source
 *	@return	NSString with all found placeholder filled
 */
- (NSString *)evaluatePlaceholderWithEntry:(KPKEntry *)entry;

@end
