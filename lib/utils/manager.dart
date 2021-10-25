
import 'package:kumav/utils/histories.dart';
import 'package:kumav/utils/plugins.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'get_ready.dart';
import 'favorites.dart';
import 'downloads.dart';

class Manager extends GetReady {
  static Manager? _instance;
  static Manager get instance {
    if (_instance == null) {
      _instance = Manager();
    }
    return _instance!;
  }

  late Favorites _favorites;
  Favorites get favorites => _favorites;

  late Downloads _downloads;
  Downloads get downloads => _downloads;

  late Plugins _plugins;
  Plugins get plugins => _plugins;

  late Histories _histories;
  Histories get histories => _histories;

  late Database database;

  @override
  Future<void> setup() async {
    var dir = await path_provider.getApplicationSupportDirectory();
    database = await databaseFactoryIo.openDatabase("${dir.path}/storage.db");
    _favorites = Favorites(database);
    await _favorites.ready;
    _downloads = Downloads(database);
    await _downloads.ready;
    _plugins = Plugins(database);
    await _plugins.ready;
    _histories = Histories(database);
    await _histories.ready;
  }


}