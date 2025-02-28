class ReportedItem {
  final String reportReason;
  final String complaintDetails;
  final String reportedBy;
  final String reportedObjectType;
  final int complaintID;
  final String itemId; // itemID parametresi

  ReportedItem({
    required this.reportReason,
    required this.complaintDetails,
    required this.reportedBy,
    required this.reportedObjectType,
    required this.complaintID,
    required this.itemId, // itemID parametresi alınıyor
  });

  // Firestore'a kaydetmek için map fonksiyonu
  Map<String, dynamic> toMap() {
    return {
      'reportReason': reportReason,
      'complaintDetails': complaintDetails,
      'reportedBy': reportedBy,
      'reportedObjectType': reportedObjectType,
      'complaintID': complaintID,
      'itemId': itemId, // itemID map'e ekleniyor
    };
  }

  // Firestore'dan gelen verilerle model oluşturma
  factory ReportedItem.fromFirestore(Map<String, dynamic> data) {
    return ReportedItem(
      reportReason: data['reportReason'],
      complaintDetails: data['complaintDetails'],
      reportedBy: data['reportedBy'],
      reportedObjectType: data['reportedObjectType'],
      complaintID: data['complaintID'],
      itemId: data['itemId'], // itemID Firestore'dan alınacak
    );
  }
}
