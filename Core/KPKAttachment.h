//
//  KPKBinaryData.h
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Binärdatenknoten */
@interface KPKAttachment : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSData *data;

- (id)initWithName:(NSString *)name value:(NSString *)value compressed:(BOOL)compressed;
- (id)initWithContentsOfURL:(NSURL *)url;

@end
