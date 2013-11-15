//
//  NSString+Commands.m
//  MacPass
//
//  Created by Michael Starke on 10/11/13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+Commands.h"

@implementation NSString (Commands)

- (NSArray *)extractCommands {
  NSUInteger commandIndex = 0;
  while(commandIndex < [self length]) {
    
  }
  return nil;
}

- (NSString *)nextCommandFromIndex:(NSUInteger)startIndex {
  return nil;
}

- (NSString *)extractSingleCommand {
  NSUInteger start = [self hasPrefix:@"{"] ? 1 : 0;
  NSUInteger end = [self hasSuffix:@"}"] ? 1 : 0;
  return [self substringWithRange:NSMakeRange(start, [self length] - start - end)];
}

- (BOOL)isSingleCommand {
  return ( [self hasPrefix:@"{"] && [self hasSuffix:@"}"] );
}

@end
