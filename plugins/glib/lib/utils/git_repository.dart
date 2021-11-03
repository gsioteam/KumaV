
import '../core/callback.dart';
import '../core/core.dart';

class GitAction extends Base {
  static reg() {
    Base.reg(GitAction, "gs::GitAction", Base)
    ..constructor = ((id) => GitAction().setID(id));
  }

  Callback? _onProgress;
  Callback? _onComplete;

  setOnProgress(void Function(String, int, int) cb) {
    _onProgress?.release();
    _onProgress = Callback.fromFunction(cb).retain();
    call("setOnProgress", argv:[_onProgress]);
  }

  setOnComplete(void Function() cb) {
    _onComplete?.release();
    _onComplete = Callback.fromFunction(cb).retain();
    call("setOnComplete", argv:[_onComplete]);
  }

  void cancel() {
    call("cancel");
  }

  bool hasError() => call("hasError");
  String getError() => call("getError");

  @override
  destroy() {
    _onProgress?.release();
    _onComplete?.release();
    super.destroy();
  }
}

class GitRepository extends Base {
  static reg() {
    Base.reg(GitRepository, "gs::GitRepository", Base)
      ..constructor = ((id) => GitRepository().setID(id));
  }

  @override
  initialize() {
    super.initialize();
  }

  GitRepository();

  GitRepository.allocate(String path, [String? branch]) {
    super.allocate([path, branch ?? "master"]);
  }

  bool isOpen() => call("isOpen");

  static void setup(String rootPath) => Base.s_call(GitRepository, "setup", argv:[rootPath]);

  static void shutdown() => Base.s_call(GitRepository, "shutdown");

  GitAction cloneFromRemote(String url) => call("cloneFromRemote", argv:[url]);

  GitAction fetch() => call("fetch");
  GitAction checkout() => call("checkout");

  String get path => call("getPath");
  String localID() => call("localID");
  String highID() => call("highID");
}