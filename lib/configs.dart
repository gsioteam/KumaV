import 'package:glib/utils/git_repository.dart';
const String env_git_url = "https://github.com/gsioteam/glib_env.git";
const String env_git_branch = "master";

Map<String, dynamic> share_cache = Map();
GitRepository env_repo;

const String collection_download = "download";
const String collection_mark = "mark";

const String home_page_name = "home";

const String direction_key = "direction";
const String device_key = "device";
const String page_key = "page";

const String history_key = "history";

const String disclaimer_key = "disclaimer";

const String language_key = "language";

const String last_video_key = "last_video";
const String video_select_key = "video_select";
const String start_time_key = "start_time";

const double MINI_SIZE = 68;
const double MINI_WIDTH = 120;

const DETAIL_INDEX = 0;
const VIDEO_INDEX = 1;