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

@class KPKEntry;
@class KPKTree;

@interface NSString (Reference)

- (BOOL)isReference;
- (NSString *)resolveReferenceWithTree:(KPKTree *)tree;
@end

@interface NSString (Placeholder)
/**
 @returns YES if the string is a simple placeholder
 */
- (BOOL)isPlaceholder;
/**
 @returns the value for this placeholderstring, nil if nothing can be found
 */
- (NSString *)placeholderValueForEntry:(KPKEntry *)entry;
/**
 *	Evaluates all placeholders inside the string an replaces them with values found in the entry
 *	@param	entry	The enty to use a source
 *  @param  didReplace YES if any replacement occured, NO otherwise (hence no placeholder was valid)
 *	@return	NSString with all found placeholder filled
 */
- (NSString *)evaluatePlaceholderWithEntry:(KPKEntry *)entry didReplace:(BOOL *)didReplace;

- (NSArray *)tokenzieSequence:(NSString *)sequence;

@end
