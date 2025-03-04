class Request {
  String requestID;
  String requestOwnerID;
  String requestContent;
  String requestStatus;
  DateTime creationDate; // Tarih bilgisi eklendi

  Request({
    required this.requestID,
    required this.requestOwnerID,
    required this.requestContent,
    required this.requestStatus,
    required this.creationDate, // Constructor'a eklendi
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      requestID: json['requestID'],
      requestOwnerID: json['requestOwnerID'],
      requestContent: json['requestContent'],
      requestStatus: json['requestStatus'],
      creationDate: DateTime.parse(json['creationDate']), // JSON dönüşümü
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestID': requestID,
      'requestOwnerID': requestOwnerID,
      'requestContent': requestContent,
      'requestStatus': requestStatus,
      'creationDate': creationDate.toIso8601String(), // JSON'a dönüştürme
    };
  }
}
