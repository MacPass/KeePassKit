//
//  KPKTokenStream.m
//  KeePassKit
//
//  Created by Michael Starke on 09.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTokenStream.h"
#import "KPKToken.h"

typedef NS_ENUM(NSInteger, KPKTokenizingState) {
  KPKTokenizingStateError,
  KPKTokenizingStateNone,
  KPKTokenizingStateCurlyCommandToken,
  KPKTokenizingStateCommandToken
};

@interface NSString (KPKTokenExtension)
@property (nonatomic, readonly) BOOL isOpenCurlyBraket;
@property (nonatomic, readonly) BOOL isClosingCurlyBraket;
@end

@implementation NSString (KPKTokenExtension)

- (BOOL)isOpenCurlyBraket {
  return [self isEqualToString:@"{"];
}

- (BOOL)isClosingCurlyBraket {
  return [self isEqualToString:@"}"];
}

@end

@interface KPKTokenStream ()

@property (copy) NSArray *tokens;
@property (nonatomic, copy) NSString *value;

@end

@implementation KPKTokenStream

+ (instancetype)tokenStreamWithValue:(NSString *)value {
  return [[KPKTokenStream alloc] initWithValue:value];
}

+ (instancetype)reducedTokenStreamWithValue:(NSString *)value {
  return [[KPKTokenStream alloc] initWithValue:value reduce:YES];
}

- (instancetype)init {
  self = [self initWithValue:@"" reduce:NO];
  return self;
}

- (instancetype)initWithValue:(NSString *)value {
  self = [self initWithValue:value reduce:NO];
  return self;
}

- (instancetype)initWithValue:(NSString *)value reduce:(BOOL)reduce {
  self = [super init];
  if(self) {
    self.value = value;
  }
  if(reduce) {
    [self _reduceTokens];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKTokenStream *copy = [[KPKTokenStream alloc] init];
  copy->_value = [_value copy];
  copy->_tokens = [[NSArray alloc] initWithArray:_tokens copyItems:YES];
  return copy;
}

- (void)setValue:(NSString *)value {
  if(![_value isEqualToString:value]) {
    _value = [value copy];
    [self _updateTokens];
  }
}

- (NSUInteger)tokenCount {
  return self.tokens.count;
}

- (void)_reduceTokens {
  // return;
}

- (KPKTokenStream *)reducedTokenStream {
  KPKTokenStream *copy = [self copy];
  [copy _reduceTokens];
  return copy;
}

- (void)_updateTokens {
  if(_value.length == 0) {
    _tokens = [@[] copy];
    return;
  }
  __block NSMutableArray *tokenStrings = [[NSMutableArray alloc] init];
  /*
   Split the string into single token strings but ensure we do not split up
   composed character e.g. emojis or accented characters
   */
  [_value enumerateSubstringsInRange:NSMakeRange(0, _value.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                            [tokenStrings addObject:substring];
                          }];
  
  NSMutableArray *tokens = [[NSMutableArray alloc] init];
  
  KPKTokenizingState state = KPKTokenizingStateNone;
  NSMutableString *tokenValue = [[NSMutableString alloc] init];
  for(NSString *string in tokenStrings) {
    
    if(state == KPKTokenizingStateError) {
      break;
    }
    
    switch(state) {
      /* no command started */
      case KPKTokenizingStateNone:
        if(string.isOpenCurlyBraket) {
          state = KPKTokenizingStateCommandToken;
          [tokenValue setString:@""]; // start collection the value;
        }
        else if(string.isClosingCurlyBraket) {
          state = KPKTokenizingStateError;
        }
        else {
          KPKToken *token = [[KPKToken alloc] initWithValue:string];
          [tokens addObject:token];
        }
        break;
      /* inside a command */
      case KPKTokenizingStateCommandToken: {
        if(string.isOpenCurlyBraket) {
          state = KPKTokenizingStateCurlyCommandToken;
          [tokenValue appendString:string]; // append {
        }
        else if(string.isClosingCurlyBraket) {
          if(tokenValue.length == 0) {
            state = KPKTokenizingStateCurlyCommandToken;
            [tokenValue appendString:string]; // append }
          }
          else {
            KPKToken *token = [[KPKToken alloc] initWithValue:[NSString stringWithFormat:@"{%@}", tokenValue]];
            [tokens addObject:token];
            [tokenValue setString:@""];
            state = KPKTokenizingStateNone;
          }
        }
        else {
          [tokenValue appendString:string];
        }
        break;
      }
      /* inside a curly command */
      case KPKTokenizingStateCurlyCommandToken:
        if(string.isClosingCurlyBraket && tokenValue.length == 1) {
          KPKToken *token = [[KPKToken alloc] initWithValue:[NSString stringWithFormat:@"{%@}", tokenValue]];
          [tokens addObject:token];
          [tokenValue setString:@""];
          state = KPKTokenizingStateNone;
        }
        else {
          state = KPKTokenizingStateError;
        }
        break;
      case KPKTokenizingStateError:
      default:
        state = KPKTokenizingStateError;
        break;
    }
  }
  self.tokens = tokens;
}


@end
