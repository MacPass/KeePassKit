//
//  KPKAnon2KeyDerivation.m
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKArgon2KeyDerivation.h"
#import "KPKNumber.h"
#import "argon2.h"

NSString *const KPKArgon2SaltOption             = @"S";
NSString *const KPKArgon2ParallelismOption      = @"P";
NSString *const KPKArgon2MemoryOption           = @"M";
NSString *const KPKArgon2IterationsOption       = @"I";
NSString *const KPKArgon2VersionOption          = @"V";
NSString *const KPKArgon2KeyOption              = @"K";
NSString *const KPKArgon2AssociativeDataOption  = @"A";

@implementation KPKArgon2KeyDerivation

+ (NSDictionary *)defaultParameters {
  return @{};
}

+ (NSUUID *)uuid {
  static const uuid_t bytes = {
    0xEF, 0x63, 0x6D, 0xDF, 0x8C, 0x29, 0x44, 0x4B,
    0x91, 0xF7, 0xA9, 0xA4, 0x03, 0xE3, 0x0A, 0x0C
  };
  static NSUUID *argon2UUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    argon2UUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
  });
  return argon2UUID;
}

- (NSData *)deriveData:(NSData *)data options:(NSDictionary *)options {
  NSData *salt = options[KPKArgon2SaltOption];
  if(salt.length == 0) {
    return nil;
  }
  KPKNumber *parallelismOptionNmb = options[KPKArgon2ParallelismOption];
  if(!parallelismOptionNmb || parallelismOptionNmb.type != KPKNumberTypeUnsignedInteger32) {
    return nil;
  }
  uint32_t parallelism = parallelismOptionNmb.unsignedInteger32Value;
  return nil;
  
  /*
   FOUNDATION_EXPORT NSString *const KPKArgon2SaltOption; // NSData
   FOUNDATION_EXPORT NSString *const KPKArgon2ParallelismOption; // uint32_t
   FOUNDATION_EXPORT NSString *const KPKArgon2MemoryOption; // utin64_t
   FOUNDATION_EXPORT NSString *const KPKArgon2IterationsOption; // utin64_t
   FOUNDATION_EXPORT NSString *const KPKArgon2VersionOption; // uint32_t
   FOUNDATION_EXPORT NSString *const KPKArgon2KeyOption; // NSData
   FOUNDATION_EXPORT NSString *const KPKArgon2AssociativeDataOption; // NSData
   */
  
}

- (instancetype)initWithOptions:(NSDictionary *)options {
  return nil;
}

+ (void)_test {
#define HASHLEN 32
#define SALTLEN 16
#define PWD "password"
  
  uint8_t hash1[HASHLEN];
  uint8_t hash2[HASHLEN];
  
  uint8_t salt[SALTLEN];
  memset( salt, 0x00, SALTLEN );
  
  uint8_t *pwd = (uint8_t *)strdup(PWD);
  uint32_t pwdlen = (uint32_t)strlen((char *)pwd);
  
  uint32_t t_cost = 2;            // 1-pass computation
  uint32_t m_cost = (1<<16);      // 64 mebibytes memory usage
  uint32_t parallelism = 1;       // number of threads and lanes
  
  // high-level API
  argon2i_hash_raw(t_cost, m_cost, parallelism, pwd, pwdlen, salt, SALTLEN, hash1, HASHLEN);
  
  // low-level API
  argon2_context context = {
    hash2,  /* output array, at least HASHLEN in size */
    HASHLEN, /* digest length */
    pwd, /* password array */
    pwdlen, /* password length */
    salt,  /* salt array */
    SALTLEN, /* salt length */
    NULL, 0, /* optional secret data */
    NULL, 0, /* optional associated data */
    t_cost, m_cost, parallelism, parallelism,
    ARGON2_VERSION_13, /* algorithm version */
    NULL, NULL, /* custom memory allocation / deallocation functions */
    ARGON2_DEFAULT_FLAGS /* by default the password is zeroed on exit */
  };
  
  int rc = argon2i_ctx( &context );
  if(ARGON2_OK != rc) {
    printf("Error: %s\n", argon2_error_message(rc));
    exit(1);
  }
  free(pwd);
  
  for( int i=0; i<HASHLEN; ++i ) printf( "%02x", hash1[i] ); printf( "\n" );
  if (memcmp(hash1, hash2, HASHLEN)) {
    for( int i=0; i<HASHLEN; ++i ) {
      printf( "%02x", hash2[i] );
    }
    printf("\nfail\n");
  }
  else printf("ok\n");
}



@end
