import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  factory Request.fromJson2(Map<String, dynamic> json) {
    return Request(
      requestID: json['requestID'],
      requestOwnerID: json['requestOwnerID'],
      requestContent: json['requestContent'],
      requestStatus: json['requestStatus'],
      creationDate: (json['creationDate'] as Timestamp).toDate(),
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

    factory Request.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Request(
      requestID: doc.id,  // Firestore ID is used as requestID
      requestOwnerID: data['requestOwnerID'] ?? '',
      requestContent: data['requestContent'] ?? '',
      requestStatus: data['requestStatus'] ?? 'pending',  // Default status if not provided
      creationDate: (data['creationDate'] as Timestamp).toDate(),  // Convert Firestore Timestamp to DateTime
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestID': requestID,
      'requestOwnerID': requestOwnerID,
      'requestContent': requestContent,
      'requestStatus': requestStatus,
      'creationDate': Timestamp.fromDate(creationDate),
    };
  }
}
