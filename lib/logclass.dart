class LogClass {
  DateTime currentTime;
  int personCount;
  String personName;
  String personAttention;
  String deviceID;
  String houseID;
  LogClass(DateTime currentTime, int personCount, String personName,
      String personAttention, String deviceID, String houseID) {
    this.currentTime = currentTime;
    this.personCount = personCount;
    this.personName = personName;
    this.personAttention = personAttention;
    this.deviceID = deviceID;
    this.houseID = houseID;
  }

  dynamic toJson() => {
        "currentTime": currentTime.toString(),
        "personCount": personCount,
        "personName": personName,
        "personAttention": personAttention,
        "deviceID": deviceID,
        "houseID": houseID,
      };
  @override
  String toString() {
    return toJson().toString();
  }
}
