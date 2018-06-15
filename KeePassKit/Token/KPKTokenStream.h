//
//  KPKTokenStream.h
//  KeePassKit
//
//  Created by Michael Starke on 09.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKToken;

@interface KPKTokenStream : NSObject <NSCopying>

@property (readonly, copy) NSArray<KPKToken *> *tokens;
@property (nonatomic, readonly) NSUInteger tokenCount;
@property (nonatomic, readonly, copy) NSString *value;

+ (instancetype)tokenStreamWithValue:(NSString *)value;
+ (instancetype)reducedTokenStreamWithValue:(NSString *)value;

/**
 Creates a token stream based on the string input.
 The stream is not preprocessed. No normalization or preprocessing is done.
 Repeats yield not rolled out commands nor do placeholders or references get retrieved.
 
 This way you can use the tokeniziation on any state.
 
 The tokenizer will at first yield a non-reduced stream, that is, for each Character a token is generated.
 If you want to have complex tokens containing more than one character at a time, send reduceTokenStream
 and work with the result.
 
 @param value stringValue to tokenize
 */
- (instancetype)initWithValue:(NSString *)value reduce:(BOOL)reduce NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithValue:(NSString *)value;

/**
 Reduces the tokenstream by merging mergeable character tokens
 */
- (KPKTokenStream *)reducedTokenStream;
@end
