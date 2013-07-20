//
//  KPKIcon.h
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKIcon : NSObject

@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, strong) NSImage *image;

- (id)initWithImageAtURL:(NSURL *)imageLocation;
- (id)initWithUUID:(NSUUID *)uuid encodedString:(NSString *)encodedString;

- (NSString *)encodedString;

@end
