//This file can be a header for test.c which wraps LibreSSL's Chacha20 API to the one provided by chacha20_simple

#include <openssl/chacha.h>
#include <endian.h>

typedef ChaCha_ctx chacha20_ctx;

static const uint8_t *nonce_last;
void chacha20_setup(chacha20_ctx *ctx, const uint8_t *key, size_t length, uint8_t nonce[8])
{
  uint8_t counter[8] = { 0 };
  ChaCha_set_key(ctx, key, length * 8);
  ChaCha_set_iv(ctx, nonce, counter);
  nonce_last = nonce;
}

void chacha20_counter_set(chacha20_ctx *ctx, uint64_t counter)
{
  counter = htole64(counter);
  ChaCha_set_iv(ctx, nonce_last, (const unsigned char *)&counter);
}

void chacha20_block(chacha20_ctx *ctx, uint32_t output[16])
{
  uint32_t input[16] = { 0 };
  ChaCha(ctx, (unsigned char *)output, (const unsigned char *)input, sizeof(input));
}

void chacha20_encrypt(chacha20_ctx *ctx, const uint8_t *in, uint8_t *out, size_t length)
{
  ChaCha(ctx, out, in, length);
}

void chacha20_decrypt(chacha20_ctx *ctx, const uint8_t *in, uint8_t *out, size_t length)
{
  ChaCha(ctx, out, in, length);
}
