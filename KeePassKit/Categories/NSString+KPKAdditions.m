//
//  NSString+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 07.03.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+KPKAdditions.h"

@implementation NSString (KPKAdditions)

+ (NSString *)stringWithEscapedRegularExpression {
  
  NSMutableString *copy = [self mutableCopy];
  
  /* * ? + [ ( ) { } ^ $ | \ . */

  NSDictionary __unused *charsToQuote = @{ @"*" : @"\\*",
                                  @"?" : @"\\?",
                                  @"+" : @"\\+",
                                  @"[" : @"\\[",
                                  @"]" : @"\\]",
                                  @"(" : @"\\(",
                                  @")" : @"\\)",
                                  @"{" : @"\\{",
                                  @"}" : @"\\}",
                                  @"^" : @"\\^",
                                  @"$" : @"\\$",
                                  @"|" : @"\\|",
                                  @"\\" : @"\\\\",
                                  @"." : @"\\."
                                  };
  
  
  [copy replaceOccurrencesOfString:@"|" withString:@"\\|" options:NSCaseInsensitiveSearch range:NSMakeRange(0, copy.length)];
  return [copy copy];
}

@end
