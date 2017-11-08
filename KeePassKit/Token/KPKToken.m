//
//  KPKToken.m
//  KeePassKit
//
//  Created by Michael Starke on 07.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKToken.h"
#import "KPKFormat.h"

NSInteger const KPKTokenInvalidLocation = NSNotFound;

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

@interface KPKToken () {
  NSInteger _location;
  NSString *_command;
}

@end

typedef NS_ENUM(NSInteger, KPKTokenizeState) {
  KPKTokenizeStateNormal,
  KPKTokenizeStateCompoundToken,
  KPKTokenizeStateCompoundCurlyToken,
  KPKTokenizeStateError
};

@implementation KPKToken

/**
 *  Mapping for modifier to CGEventFlags.
 *
 *  @return dictionary with commands as keys and CGEventFlags as wrapped values
 */
+ (NSDictionary *)_modifierCommands {
  static NSDictionary *modifierCommands;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    modifierCommands = @{
                         /*kKPKAutotypeAlt : @(kCGEventFlagMaskAlternate),
                         kKPKAutotypeControl : @(kCGEventFlagMaskControl),
                         kKPKAutotypeShift : @(kCGEventFlagMaskShift)
                          */
                         };
  });
  return modifierCommands;
}

+ (NSArray<KPKToken *> *)tokenizeString:(NSString *)string {
  if(!string) {
    return nil;
  }
  __block NSMutableString *tokenValue = [[NSMutableString alloc] init];
  __block KPKTokenizeState state = KPKTokenizeStateNormal;
  __block NSMutableArray *tokens = [[NSMutableArray alloc] initWithCapacity:MAX(1,string.length)];
  [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                            switch(state) {
                              case KPKTokenizeStateNormal: {
                                if(substring.isOpenCurlyBraket) {
                                  [tokenValue setString:@"{"];
                                  state = KPKTokenizeStateCompoundToken;
                                }
                                else if(substring.isClosingCurlyBraket) {
                                  state = KPKTokenizeStateError;
                                }
                                else {
                                  KPKToken *token = [[KPKToken alloc] initWithValue:substring];
                                  if(token) {
                                    [tokens addObject:token];
                                  }
                                  else {
                                    state = KPKTokenizeStateError;
                                  }
                                }
                                break;
                              }
                              case KPKTokenizeStateCompoundToken: {
                                if(substring.isClosingCurlyBraket) {
                                  if(tokenValue.length == 1) {
                                    [tokenValue appendString:substring];
                                    state = KPKTokenizeStateCompoundCurlyToken;
                                  }
                                  else {
                                    state = KPKTokenizeStateNormal;
                                    [tokenValue appendString:substring];
                                    KPKToken *token = [[KPKToken alloc] initWithValue:tokenValue];
                                    if(token) {
                                      [tokens addObject:token];
                                    }
                                    else {
                                      state = KPKTokenizeStateError;
                                    }
                                    /* clear tokenvalue */
                                    [tokenValue setString:@""];
                                  }
                                }
                                else {
                                  if(substring.isOpenCurlyBraket) {
                                    state = KPKTokenizeStateCompoundCurlyToken;
                                  }
                                  [tokenValue appendString:substring];
                                }
                                break;
                              }
                              case KPKTokenizeStateCompoundCurlyToken:
                                if(substring.isClosingCurlyBraket) {
                                  state = KPKTokenizeStateNormal;
                                  [tokenValue appendString:substring];
                                  KPKToken *token = [[KPKToken alloc] initWithValue:tokenValue];
                                  if(token) {
                                    [tokens addObject:token];
                                  }
                                  else {
                                    state = KPKTokenizeStateError;
                                  }
                                  /* clear tokenvalue */
                                  [tokenValue setString:@""];
                                }
                                else {
                                  state = KPKTokenizeStateError;
                                }
                                break;
                              case KPKTokenizeStateError:
                              default:
                                state = KPKTokenizeStateError;
                                *stop = YES;
                                break;
                            }
                          }];
  return [tokens copy];
}

- (instancetype)init {
  self = [self initWithValue:@"" location:KPKTokenInvalidLocation];
  return self;
}

- (instancetype)initWithValue:(NSString *)value {
  self = [self initWithValue:value location:KPKTokenInvalidLocation];
  return self;
}

- (instancetype)initWithValue:(NSString *)value location:(NSInteger)location {
  if(!value) {
    [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Token value cannot be nil!" userInfo:nil] raise];
    self = nil;
    return self;
  }
  self = [super init];
  if(self) {
    _location = location;
    _value = [value copy];
    [self _parseValue];
    
  }
  return self;
}

- (NSString *)description {
  return self.value.description;
}


- (void)_parseValue {
  if(self.value.length > 2 && [self.value hasPrefix:@"{"] && [self.value hasSuffix:@"}"]) {
    _command = [self.value substringWithRange:NSMakeRange(1, self.value.length - 2)];
  }
}

@end
