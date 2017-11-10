//
//  KPKEntry_Private.h
//  MacPass
//
//  Created by Michael Starke on 19/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import "KPKEntry.h"
#import "KPKNode_Private.h"

@interface KPKEntry ()
@property (nonatomic, copy) KPKAutotype *autotype;
@property (nonatomic, strong) NSMutableArray<KPKAttribute *> *mutableAttributes;
@property (nonatomic, strong) NSMutableArray<KPKBinary *> *mutableBinaries;
@property (nonatomic, strong) NSMutableArray<KPKEntry *> *mutableHistory;
/**
 *  Generic getter for the protected property of a attribute with the supplied key,
 *
 *  @param key The key for the attribute to test for protection
 *
 *  @return YES if the attribute is protected, NO if not or if it wasn't found
 */
- (BOOL)_protectValueForKey:(NSString *)key;
/**
 *  Sets the protected value for the attribute with the given key
 *
 *  @param protect The value for the protected flag
 *  @param key     The key for the attribute to set the protected flag
 */
- (void)_setProtect:(BOOL)protect valueForkey:(NSString *)key;
/**
 *  Sets the value for the attribute with the given key
 *
 *  @param value Value to set
 *  @param key   Key for the attribute to set the value upon
 */
- (void)_setValue:(NSString *)value forAttributeWithKey:(NSString *)key;

/**
 *	Adds an Item to the Entries history
 *	@param	entry	Entry element to be added as history
 */
- (void)_addHistoryEntry:(KPKEntry *)entry;

- (void)_pushHistoryAndMaintain:(BOOL)maintain;

/**
 *  Updates history entries to adhere to settings in tree's metadata
 */
- (void)_maintainHistory;

@end
