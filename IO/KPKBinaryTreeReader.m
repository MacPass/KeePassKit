//
//  KPKBinaryTreeReader.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKBinaryTreeReader.h"
#import "KPKBinaryCipherInformation.h"

@interface KPKBinaryTreeReader () {
  NSData *_data;
  KPKBinaryCipherInformation *_cipherInfo;
}

@end

@implementation KPKBinaryTreeReader

- (id)initWithData:(NSData *)data chipherInformation:(KPKBinaryCipherInformation *)cipherInfo {
  self = [super init];
  if(self) {
    _data = data;
    _cipherInfo = cipherInfo;
  }
  return self;
}

- (KPKTree *)tree {
  /*
  levels = [[NSMutableArray alloc] initWithCapacity:numGroups];
  groups = [[NSMutableArray alloc] initWithCapacity:numGroups];
  entries = [[NSMutableArray alloc] initWithCapacity:numEntries];
  
  @try {
    // Parse groups
    [self readGroups:aesInputStream];
    
    // Parse entries
    [self readEntries:aesInputStream];
    
    // Build the tree
    return [self buildTree];
  } @finally {
    aesInputStream = nil;
  }*/
  return nil;
}

@end
