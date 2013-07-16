//
//  NSUUID+KeePassKit.h
//  KeePassKit
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUUID (KeePassKit)

+ (NSUUID *)nullUUID;
+ (NSUUID *)AESUUID;
- (NSString *)encodedString;

@end
