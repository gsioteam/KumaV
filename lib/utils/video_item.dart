
abstract class ToData {
  dynamic toData();
}

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
    this.customer,
  });

  ItemData.fromData(Map data) :
        key = data["key"],
        data = data["data"],
        pluginID = data["pluginID"],
        date = data["date"],
        customer = data["customer"];

  Map toData() {
    return {
      "key": key,
      "data": (data is ToData) ? data.toData() : data,
      "pluginID": pluginID,
      "date": date,
      "customer": (customer is ToData) ? customer.toData() : customer,
    };
  }

  String get picture => data["picture"];
  String get title => data["title"];
  String get subtitle => data["subtitle"];
}