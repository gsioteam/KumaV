//
// Created by gen on 11/2/21.
//

#ifndef ANDROID_SECP256K1_H
#define ANDROID_SECP256K1_H

#include <core/Ref.h>
#include "../gs_define.h"
namespace gs {
    CLASS_BEGIN_N(Secp256k1, gc::Object)

        METHOD static  bool verify(const std::string& pubKey, const std::string &token, const std::string &url, const std::string &prev);

    public:
        ON_LOADED_BEGIN(cls, gc::Object)
            ADD_METHOD(cls, Secp256k1, verify);
        ON_LOADED_END

    CLASS_END
}


#endif //ANDROID_SECP256K1_H
