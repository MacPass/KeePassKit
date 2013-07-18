//
//  NSString+KPKCommandString.h
//  MacPass
//
//  Created by Michael Starke on 17.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@end
