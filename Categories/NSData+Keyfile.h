//
//  NSData+Keyfile.h
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Keyfile)

+ (NSData *)dataWithWithContentsOfKeyFile:(NSURL *)url error:(NSError **)error;

@end
