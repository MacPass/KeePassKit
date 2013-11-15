//
//  NSString+Commands.h
//  MacPass
//
//  Created by Michael Starke on 10/11/13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Commands)
/**
 *  The reveiver is searched from the given index for a valid command. This can be a placeholder or a special key or some complex command.
 *  @param startIndex [in/out] the index to start searching for the next command.
 *  It is moved forward after something is found by the lenght of the returnde command (in the string)
 *
 *  @return String containing the encountered next command. nil if none was found
 */
- (NSString *)nextCommandFromIndex:(NSUInteger)startIndex;
- (NSArray *)extractCommands;
- (NSString *)extractSingleCommand;
- (BOOL)isSingleCommand;

@end
