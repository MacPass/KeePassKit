//
//  KPKKey.h
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import Foundation;

@interface KPKKey : NSObject

@property (nonatomic, readonly, copy) NSData *data;

+ (instancetype)keyWithContentOfURL:(NSURL *)url;
+ (instancetype)keyWithPassword:(NSString *)password;

- (instancetype)initWithPassword:(NSString *)password;
- (instancetype)initWithContentOfURL:(NSURL *)url;

@end
