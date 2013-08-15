//
//  NSString+Placeholder.h
//  MacPass
//
//  Created by Michael Starke on 15.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KPKEntry;

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

@end
