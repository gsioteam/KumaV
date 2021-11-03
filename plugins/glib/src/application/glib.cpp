//
// Created by gen on 8/25/20.
//

#include "glib.h"
#include <core/Ref.h>
#include <core/Callback.h>
#include <core/Array.h>
#include <core/Map.h>
#include "utils/Platform.h"
#include "utils/GitRepository.h"
#include "utils/Bit64.h"
#include "utils/dart/DartPlatform.h"
#include "utils/Secp256k1.h"

using namespace gc;

extern "C" void initGlib() {
    ClassDB::reg<gc::_Map>();
    ClassDB::reg<gc::_Array>();
    ClassDB::reg<gc::_Callback>();
    ClassDB::reg<gc::FileData>();
    ClassDB::reg<gs::GitRepository>();
    ClassDB::reg<gs::DartPlatform>();
    ClassDB::reg<gs::GitAction>();
    ClassDB::reg<gs::Bit64>();
    ClassDB::reg<gs::Platform>();
    ClassDB::reg<gs::Secp256k1>();
}


