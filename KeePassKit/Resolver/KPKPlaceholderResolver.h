//
//  KPKPlaceholderResolver.h
//  KeePassKit
//
//  Created by Michael Starke on 25.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKPlaceholderResolver : NSObject
/**
 return YES if you resolver works case senstitive, default is NO
 */
@property (nonatomic) BOOL resolvesCaseSensitive;
/**
 Return YES if your resolver requires user interaction. Default is NO. Interactive resovler might not be called in certain situations!
 */
@property (nonatomic) BOOL interactive;

/**
 register the resolver. You should call this to ensure the resolver is know to KeePassKit
 A good place to do this is inside the +load implementation of you resolver
 */
+ (void)registerResolver;

/**
 This is the main entry for you resolver. Every registered placeholder will get called with the current evaluated sequence.
 You will get handed down a NSMutableDictionary into which you can add you own resolved values.
 The key is a substring of the input string and should not overlap with other placeholders.

 @param string String that is being evaluated, if no placeholder is present, just return NO and do not add anything to the dictionary
 @return YES if placeholders were evaluated and the mappings were updated
 */
- (BOOL)resolvedPlaceholders:(NSMutableDictionary <NSString *, NSString *> * _Nonnull __autoreleasing *_Nonnull)mappings inString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
