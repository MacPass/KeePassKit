//
//  KPKKeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const kKPKKeyDerivationUUID; // Option to supply the UUID for the derivation

@interface KPKKeyDerivation : NSObject

- (NSData *)deriveData:(NSData *)data options:(NSDictionary *)options;

@end
