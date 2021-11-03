//
// Created by gen on 11/2/21.
//

#include "Secp256k1.h"
#include <secp256k1.h>
#include <sha256/sha256.h>
#include <bit64/bit64.h>


using namespace gs;

bool Secp256k1::verify(const std::string &pubKey, const std::string &token, const std::string &url, const std::string &prev) {
    sha256_context sha256_ctx;
    sha256_init(&sha256_ctx);
    if (!prev.empty()) {
        b8_vector data;
        data.resize(bit64_decode_size(prev.size()));
        size_t d_size = bit64_decode((const uint8_t *)prev.data(), prev.size(), data.data());
        sha256_hash(&sha256_ctx, data.data(), d_size);
    }
    sha256_hash(&sha256_ctx, (uint8_t *)url.data(), url.size());
    uint8_t sha256_res[32];
    sha256_done(&sha256_ctx, sha256_res);

    secp256k1_context *secp256k1_ctx = secp256k1_context_create(SECP256K1_CONTEXT_VERIFY);
    secp256k1_pubkey pubkey;
    uint8_t public_key[33];
    size_t pub_len = bit64_decode((const uint8_t *)pubKey.data(), pubKey.size(), public_key);
    if (!secp256k1_ec_pubkey_parse(secp256k1_ctx, &pubkey, public_key, pub_len)) {
        return false;
    }
    uint8_t test[65];
    size_t test_size = 65;
    secp256k1_ec_pubkey_serialize(secp256k1_ctx, test, &test_size, &pubkey, SECP256K1_EC_UNCOMPRESSED);
    secp256k1_ecdsa_signature signature;
    size_t dec_size = bit64_decode_size(token.size());
    if (dec_size != 64 && dec_size != 65) {
        return false;
    }
    uint8_t *buf = (uint8_t *)malloc(dec_size);
    dec_size = bit64_decode((const uint8_t *)token.data(), token.size(), buf);
    if (dec_size != 64) {
        free(buf);
        return false;
    }
    secp256k1_ecdsa_signature_parse_compact(secp256k1_ctx, &signature, buf);
    free(buf);
    return secp256k1_ecdsa_verify(secp256k1_ctx, &signature, sha256_res, &pubkey);
}