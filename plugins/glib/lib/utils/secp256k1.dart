
import 'package:glib/core/core.dart';

class Secp256k1 extends Base {
  static reg() {
    Base.reg(Secp256k1, "gs::Secp256k1", Base);
  }

  static bool verify(String pubKey, String token, String url, String prev) =>
      Base.s_call(Secp256k1, "verify", argv: [pubKey, token, url, prev]);
}