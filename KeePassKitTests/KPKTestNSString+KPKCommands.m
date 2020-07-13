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

@interface KPKTestNSStringCommands : XCTestCase <KPKTreeDelegate>
@end

@implementation KPKTestNSStringCommands

- (void)testCommandValidation {
  XCTAssertFalse(@"".kpk_validCommand, @"Emptry strings aren't valid commands");
}

- (void)testSimpleNormalization {
  XCTAssertEqualObjects(@"Whoo %{%}{^}{SHIFT}+ {SPACE}{ENTER}^V%V~T".kpk_normalizedAutotypeSequence, @"Whoo{SPACE}{ALT}{PERCENT}{CARET}{SHIFT}{SHIFT}{SPACE}{SPACE}{ENTER}{CONTROL}V{ALT}V{ENTER}T");
}

- (void)testCommandRepetition {
  XCTAssertEqualObjects(@"Whoo %{% 2}{^}{SHIFT 5}+ {SPACE}{ENTER}^V%V~T".kpk_normalizedAutotypeSequence, @"Whoo{SPACE}{ALT}{PERCENT}{PERCENT}{CARET}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SPACE}{SPACE}{ENTER}{CONTROL}V{ALT}V{ENTER}T");
  XCTAssertEqualObjects(@"{TAB 5}TAB{TAB}{SHIFT}{SHIFT 10}ENTER{ENTER}{%%}".kpk_normalizedAutotypeSequence, @"{TAB}{TAB}{TAB}{TAB}{TAB}TAB{TAB}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}{SHIFT}ENTER{ENTER}{%%}");
}

- (void)testNumberedKeys {
  XCTAssertEqualObjects(@"{F1}{F2}{NUMPAD3}".kpk_normalizedAutotypeSequence, @"{F1}{F2}{NUMPAD3}");
  XCTAssertEqualObjects(@"{F1 2}{NUMPAD1 3}".kpk_normalizedAutotypeSequence, @"{F1}{F1}{NUMPAD1}{NUMPAD1}{NUMPAD1}");
}

- (void)testComplexCommandNormalization {
  NSString *sequence = [NSString stringWithFormat:@"{TAB 2}{s:1}{s: 1}{%@ 10}{%@ 10}{%@ 10}{%@ 10}", kKPKAutotypeVirtualKey, kKPKAutotypeVirtualExtendedKey, kKPKAutotypeVirtualNonExtendedKey, kKPKAutotypeDelay];
  NSString *result = [NSString stringWithFormat:@"{TAB}{TAB}{s:1}{s: 1}{%@ 10}{%@ 10}{%@ 10}{%@ 10}", kKPKAutotypeVirtualKey, kKPKAutotypeVirtualExtendedKey, kKPKAutotypeVirtualNonExtendedKey, kKPKAutotypeDelay];
  XCTAssertEqualObjects(sequence.kpk_normalizedAutotypeSequence, result);
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
      XCTAssertNotNil(command.kpk_normalizedAutotypeSequence);
    }
  }];
}


- (void)testKDBAutotypeImport {
  NSString *string = @"Auto-Type: {USERNAME}{TAB}{PASSWORD}{ENTER}\nAuto-Type-Window: Some Dialog - *\nAuto-Type-1: {USERNAME}{ENTER}\nAuto-Type-Window-1: * - Editor\nAuto-Type-Window-1: * - Notepad\nAuto-Type-Window-1: * - WordPad\nAuto-Type-2: {PASSWORD}{ENTER}\nAuto-Type-Window-2: Some Web Page - *";
  
}

- (void)testKDBAutotypeExport {
}

- (void)testCustomFieldPlaceholder {
  KPKEntry *entry = [[KPKEntry alloc] init];
  KPKAttribute *camelCase = [[KPKAttribute alloc] initWithKey:@"Key A" value:@"Value A"];
  KPKAttribute *lowerCase = [[KPKAttribute alloc] initWithKey:@"key A" value:@"value A"];
  KPKAttribute *spacedLetter = [[KPKAttribute alloc] initWithKey:@" key A" value:@" value A"];
  KPKAttribute *spacedNumber = [[KPKAttribute alloc] initWithKey:@" 1" value:@" value 1"];
  [entry addCustomAttribute:camelCase];
  [entry addCustomAttribute:lowerCase];
  [entry addCustomAttribute:spacedLetter];
  [entry addCustomAttribute:spacedNumber];
  
  NSString *sequence = [NSString stringWithFormat:@"{s:%@}{s:%@}{S:%@}{S:%@}", camelCase.key, lowerCase.key, spacedLetter.key, spacedNumber.key];
  XCTAssertEqualObjects(sequence, sequence.kpk_normalizedAutotypeSequence);
  NSString *result = [NSString stringWithFormat:@"%@%@%@%@", camelCase.value, lowerCase.value, spacedLetter.value, spacedNumber.value];
  XCTAssertEqualObjects([sequence kpk_finalValueForEntry:entry], result);
}

- (void)testHasReference {
  XCTAssertFalse(@"ThisIsNoReferencRef:".kpk_hasReference);
  XCTAssertFalse(@"ThisIsNoReferenc{Ref:".kpk_hasReference);
  XCTAssertFalse(@"ThisIsNoReferencRef:}".kpk_hasReference);
  XCTAssertFalse(@"ThisIsNoReferenc{Ref:}".kpk_hasReference);
  XCTAssertFalse(@"ThisIsNoReferenc{Ref:A@I:".kpk_hasReference);
  XCTAssertFalse(@"ThisIsNoReferencRef:A@I:}".kpk_hasReference);
  
  XCTAssertTrue(@"ThisIsAReferenc{Ref:A@I:}".kpk_hasReference);
  XCTAssertTrue(@"ThisIsAReferenc{Ref:U@U:}".kpk_hasReference);
}

- (void)testNonInteractiveOption {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  tree.delegate = self;
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root];
  entry.username = @"User";
  NSString *sequence = @"{PICKCHARS}{USERNAME}{PICKFIELD}{USERNAME}";
  NSString *result = [NSString stringWithFormat:@"{PICKCHARS}%@{PICKFIELD}%@", entry.username, entry.username];
  XCTAssertEqualObjects([sequence kpk_finalValueForEntry:entry options:KPKCommandEvaluationOptionSkipUserInteraction], result);
}

/*
- (NSString *)tree:(KPKTree *)tree resolvePlaceholder:(NSString *)placeholder forEntry:(KPKEntry *)entry;
 */
- (NSString *)tree:(KPKTree *)tree resolvePickCharsPlaceholderForEntry:(KPKEntry *)entry field:(NSString *_Nullable)field options:(NSString *_Nullable)options {
  return @"{RESOLVED-PICKCHARS}";
}
- (NSString *)tree:(KPKTree *)tree resolveHMACOTPPlaceholderForEntry:(KPKEntry *)entry {
  return @"{RESOLVED-HMACOTP}";
}
- (NSString *)tree:(KPKTree *)tree resolvePickFieldPlaceholderForEntry:(KPKEntry *)entry {
  return @"{RESOLVEDPICKFIELD}";
}



@end
