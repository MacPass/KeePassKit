//
//  KPKTimerecording.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KPKTimerecording <NSObject>

@required
/**
 If property is set to NO, changes will not affect times
 If YES, changes will result in updated times
 */
@property (nonatomic, assign) BOOL updateTiming;

@end
