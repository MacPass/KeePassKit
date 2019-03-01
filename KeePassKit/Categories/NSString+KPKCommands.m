//  NSString+Commands.m
//
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

#import "NSString+KPKCommands.h"
#import "KPKNode_Private.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKAttribute.h"
#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKGroup.h"
#import "NSUUID+KPKAdditions.h"
#import "KPKFormat.h"
#import "KPKCommandParser.h"

@implementation NSString (KPKAutotype)

- (NSString *)kpk_normalizedAutotypeSequence {
  return [KPKCommandParser nomarlizedAutotypeSequenceForSequece:self];
}

- (BOOL)kpk_validCommand {
  /* TODO: Cache result? */
  if(self.length == 0) {
    return NO;
  }
  NSUInteger index = 0;
  BOOL isBracketOpen = NO;
  while(YES) {
    if(index >= self.length) {
      /* At the end all brackets should be closed */
      return !isBracketOpen;
    }
    NSUInteger openingBracketIndex = [self rangeOfString:@"{" options:0 range:NSMakeRange(index, self.length - index)].location;
    NSUInteger closingBracketIndex = [self rangeOfString:@"}" options:0 range:NSMakeRange(index, self.length - index)].location;
    if(isBracketOpen) {
      if(closingBracketIndex != NSNotFound && closingBracketIndex < openingBracketIndex) {
        isBracketOpen = NO;
        index = (1 + closingBracketIndex);
        continue;
      }
      return NO; // Missing closing or we got another opening one before the next closing one
    }
    else if(openingBracketIndex != NSNotFound ) {
      if( openingBracketIndex < closingBracketIndex ) {
        isBracketOpen = YES;
        index = (1 + openingBracketIndex);
        continue;
      }
      return NO; // There is another closing braket before the opening one
    }
    return (closingBracketIndex == NSNotFound);
  }
}
@end


@implementation NSString (KPKEvaluation)

- (BOOL)kpk_hasReference {
  return [KPKCommandParser hasReferenceInSequence:self];
}

- (NSString *)kpk_finalValueForEntry:(KPKEntry *)entry {
  return [self kpk_finalValueForEntry:entry options:0];
}

- (NSString *)kpk_finalValueForEntry:(KPKEntry *)entry options:(KPKCommandEvaluationOptions)options {
  KPKCommandEvaluationContext *context = [KPKCommandEvaluationContext contextWithEntry:entry options:options];
  KPKCommandParser *parser = [[KPKCommandParser alloc] initWithSequnce:self context:context];
  return parser.finalValue;
}

@end
