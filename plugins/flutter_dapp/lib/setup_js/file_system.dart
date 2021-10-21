
import 'package:js_script/filesystems.dart';
import 'package:js_script/js_script.dart';
import 'setup.dart' as setup;

JsFileSystem fileSystem = MemoryFileSystem({
  "/setup.js": setup.js,
});