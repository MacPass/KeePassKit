//
//  KPKTestAutotypeNormalization.m
//  MacPass
//
//  Created by Michael Starke on 18.02.14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestAutotype : XCTestCase
@end

@implementation KPKTestAutotype

- (void)testCommandValidation {
  XCTAssertFalse(@"".kpk_validCommand, @"Emptry strings aren't valid commands");
}

- (void)testSimpleNormalization {
  XCTAssertTrue([@"Whoo %{%}{^}{SHIFT}+ {SPACE}{ENTER}^V%V~T".kpk_normalizedAutotypeSequence isEqualToString:@"Whoo{SPACE}{ALT}{PERCENT}{CARET}{SHIFT}{SHIFT}{SPACE}{SPACE}{ENTER}{CONTROL}V{ALT}V{ENTER}T"]);
}

- (void)testCommandRepetition {
  XCTAssertTrue([@"Whoo %{% 2}{^}{SHIFT 5}+ {SPACE}{ENTER}^V%V~T".kpk_normalizedAutotypeSequence isEqualToString:@"Whoo{SPACE}{ALT}{PERCENT}{PERCENT}{CARET}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SPACE}{SPACE}{ENTER}{CONTROL}V{ALT}V{ENTER}T"]);
  XCTAssertTrue([@"{TAB 5}TAB{TAB}{SHIFT}{SHIFT 10}ENTER{ENTER}{%%}".kpk_normalizedAutotypeSequence isEqualToString:@"{TAB}{TAB}{TAB}{TAB}{TAB}TAB{TAB}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}ENTER{ENTER}{%%}"]);
}

- (void)testeBracketValidation {
  XCTAssertFalse(@"{BOOO}NO-COMMAND{TAB}{WHOO}{WHOO}{SPACE}!!!thisIsFun{{MISMATCH!!!}".kpk_validCommand);
  XCTAssertFalse(@"{{}}}}".kpk_validCommand);
  XCTAssertFalse(@"{}{}{{{}{{{{{{}}".kpk_validCommand);
  XCTAssertTrue(@"{}{}{}{}{}{      }ThisIsValid{}{STOP}".kpk_validCommand);
}


- (void)testCommandCachePerformance {
  NSString *command = @"MyCustomCommand";
  [self measureBlock:^{
    NSUInteger count = 1000000;
    while(count--) {
      NSString *hit = command.kpk_normalizedAutotypeSequence;
    }
  }];
}


- (void)testKDBAutotypeImport {
  NSString *string = @"Auto-Type: {USERNAME}{TAB}{PASSWORD}{ENTER}\nAuto-Type-Window: Some Dialog - *\nAuto-Type-1: {USERNAME}{ENTER}\nAuto-Type-Window-1: * - Editor\nAuto-Type-Window-1: * - Notepad\nAuto-Type-Window-1: * - WordPad\nAuto-Type-2: {PASSWORD}{ENTER}\nAuto-Type-Window-2: Some Web Page - *";
  KPKAutotype *autotype = [KPKAutotype autotypeFromNotes:string];
}

- (void)testKDBAutotypeExport {
}

- (void)testCustomFieldPlaceholder {
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@"Key A" value:@"Value A"]];
  [entry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@"key A" value:@"value A"]];
  
  NSString *sequence1 = [NSString stringWithFormat:@"{S:%@}", entry.customAttributes[0].key].kpk_normalizedAutotypeSequence;
  XCTAssertEqualObjects([sequence1 kpk_evaluatePlaceholderWithEntry:entry], entry.customAttributes[0].value);

  
  NSString *sequence2 = [NSString stringWithFormat:@"{S:%@}", entry.customAttributes[1].key].kpk_normalizedAutotypeSequence;
  XCTAssertEqualObjects([sequence2 kpk_evaluatePlaceholderWithEntry:entry], entry.customAttributes[1].value);
}

@end
