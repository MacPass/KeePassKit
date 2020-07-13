//
//  KPKAutotypeNotesSerializer.m
//  KeePassKit
//
//  Created by Michael Starke on 11.03.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAutotypeNotesSerializer.h"
#import "KPKAutotype.h"
#import "KPKWindowAssociation.h"

static NSString *const KPKAutotypeNotesAutotypePrefix       = @"Auto-Type";
static NSString *const KPKAutotypeNotesAutotypeWindowPrefix = @"Auto-Type-Window";

typedef NS_ENUM (NSUInteger, KPKAutotypeNotesParserState) {
  KPKAutotypeNotesParserStateFirstSequnce,
  KPKAutotypeNotesParserStateSequence,
  KPKAutotypeNotesParserStateWindow
};

NSString *autotypePrefixForIndex(NSUInteger index) {
  if(index == 0) {
    return [NSString stringWithFormat:@"%@:", KPKAutotypeNotesAutotypePrefix];
  }
  return [NSString stringWithFormat:@"%@-%ld:", KPKAutotypeNotesAutotypePrefix, index];
  
}
NSString *autotypeWindowPrefixForIndex(NSUInteger index) {
  if(index == 0) {
    return [NSString stringWithFormat:@"%@:", KPKAutotypeNotesAutotypeWindowPrefix];
  }
  return [NSString stringWithFormat:@"%@-%ld:", KPKAutotypeNotesAutotypeWindowPrefix, index];
}

@interface KPKAutotypeNoteEntry ()

@property (copy) NSString *sequence;
@property (strong) NSMutableArray<NSString *> *mutableWindowTitles;

@end

@implementation KPKAutotypeNoteEntry

- (instancetype)initWithSequence:(NSString *)sequence {
  self = [super init];
  if(self) {
    self.sequence = sequence;
    self.mutableWindowTitles = [[NSMutableArray alloc] init];
  }
  return self;
}

- (instancetype)init {
  self = [self initWithSequence:@""];
  return self;
}

- (NSArray<NSString *> *)windowTitles {
  return [self.mutableWindowTitles copy];
}

- (void)addWindowTitle:(NSString *)windowTitle {
  [self.mutableWindowTitles addObject:windowTitle];
}

@end

@interface KPKAutotypeNotesSerializer ()

@property (copy) NSString *notes;
@property (strong) NSMutableArray<KPKAutotypeNoteEntry *> *mutableAutotypeEntries;

@end

@implementation KPKAutotypeNotesSerializer

- (instancetype)initWithNotes:(NSString *)notes {
  self = [super init];
  if(self) {
    self.notes = notes;
  }
  return self;
}

- (instancetype)init {
  self = [self initWithNotes:@""];
  return self;
}

- (NSArray<KPKAutotypeNoteEntry *> *)autotypeEntries {
  [self _parseNotes];
  return [self.mutableAutotypeEntries copy];
}

- (void)_parseNotes {
  NSArray<NSString *> *lines = [self.notes componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  
  NSUInteger currentLineNumber = 0;
  while(currentLineNumber < lines.count) {
    NSString *line = lines[currentLineNumber];
    [self _parseSequenceInLine:line];
    [self _parseWindowTitleInLine:line];
    currentLineNumber++;
  }
}

- (void)_parseSequenceInLine:(NSString *)line {
  NSString *prefix = autotypePrefixForIndex(self.mutableAutotypeEntries.count);
  if(![line hasPrefix:prefix]) {
    return;
  }
  NSString *sequence = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if(sequence.length > 0 ) {
    [self.mutableAutotypeEntries addObject:[[KPKAutotypeNoteEntry alloc] initWithSequence:sequence]];
  }
}

- (void)_parseWindowTitleInLine:(NSString *)line {
  if(self.mutableAutotypeEntries.count == 0) {
    return; // w
  }
  NSString *prefix = autotypeWindowPrefixForIndex(self.mutableAutotypeEntries.count);
}

- (NSString *)serializeAutotype:(KPKAutotype *)autotype {
  return @"";
}

@end
