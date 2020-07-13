//
//  KPKAutotypeNotesSerializer.h
//  KeePassKit
//
//  Created by Michael Starke on 11.03.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKAutotypeNoteEntry : NSObject

@property (readonly, copy) NSString *sequence;
@property (readonly, copy) NSArray<NSString *> *windowTitles;

- (instancetype)initWithSequence:(NSString *)sequence;
- (void)addWindowTitle:(NSString *)windowTitle;

@end

@class KPKAutotype;

@interface KPKAutotypeNotesSerializer : NSObject

@property (readonly, copy) NSArray<KPKAutotypeNoteEntry *> *autotypeEntries;

- (instancetype)initWithNotes:(NSString *)notes NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
