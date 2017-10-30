//
//  KPKTree+KPKFormatSupport.m
//  KeePassKit
//
//  Created by Michael Starke on 30.10.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"
#import "KPKFormat.h"
#import "KPKEntry_Private.h"
#import "KPKGroup.h"

@implementation KPKTree (FormatSupport)

- (KPKFileVersion)minimumVersionForAddingEntryToGroup:(KPKGroup *)group {
  if(group.parent != nil) {
    return KPKMakeFileVersion(KPKDatabaseFormatKdb, kKPKKdbFileVersion);
  }
  return KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3);
}

- (KPKFileVersion)minimumVersionForAddingAttachmentToEntry:(KPKEntry *)entry {
  if(entry.mutableBinaries.count == 0) {
    return KPKMakeFileVersion(KPKDatabaseFormatKdb, kKPKKdbFileVersion);
  }
  return KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3);
}
- (KPKFileVersion)minimumVersionForHistory {
  return KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3);
}

- (KPKFileVersion)minimumVersionForAddingAttribute {
  return KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3);
}

@end
