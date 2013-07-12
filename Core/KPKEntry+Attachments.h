//
//  KPKEntry+Attachments.h
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKEntry.h"

@interface KPKEntry (Attachments)

- (BOOL)addBinaryWithContentsOfURL:(NSURL *)url error:(NSError **)error;

@end
