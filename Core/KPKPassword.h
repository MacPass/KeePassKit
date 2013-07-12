//
//  KPKPassword.h
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKDatabaseVersion.h"

@interface KPKPassword : NSObject

/*
 The password class to be able to decrypt and encrypt databses
 Neither the password nor the keyfile are stored and just read
 and hashed into the composite key.
 
 The Final key is then created before a write or read gets performend
 */
@property (nonatomic, readonly) NSData *compositeData;

- (id)initWithPassword:(NSString *)password key:(NSURL *)url;
/*
 @return the final Data to use to en/decrypt the database
 */
- (NSData *)finalDataForVersion:(KPKDatabaseVersion )version
                     masterSeed:(NSData *)masterSeed
                  transformSeed:(NSData *)transformSeed
                         rounds:(NSUInteger )rounds;

@end
