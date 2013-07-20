//
//  KPKChipherInformation.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKChipherInformation : NSObject {
  NSUUID *cipherUuid;
  uint32_t compressionAlgorithm;
  NSData *masterSeed;
  NSData *transformSeed;
  uint64_t rounds;
  NSData *encryptionIv;
  NSData *protectedStreamKey;
  NSData *streamStartBytes;
  uint32_t randomStreamID;
@private
  NSData *_comment;
  NSUInteger _endOfHeader;
  NSData *_data;
}

- (id)initWithData:(NSData *)data error:(NSError **)error;
- (NSData *)payload;

@end
