

class ItemData {
  String key;
  dynamic data;
  String pluginID;
  int date;
  dynamic customer;

  ItemData({
    required this.key,
    required this.pluginID,
    required this.date,
    this.data,
  });

  ItemData.fromData(Map data) :
        key = data["key"],
        data = data["data"],
        pluginID = data["pluginID"],
        date = data["date"];

  Map toData() {
    return {
      "key": key,
      "data": data,
      "pluginID": pluginID,
      "date": date,
    };
  }

  String get picture => data["picture"];
  String get title => data["title"];
  String get subtitle => data["subtitle"];
}