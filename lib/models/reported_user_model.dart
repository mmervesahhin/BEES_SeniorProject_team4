class ReportedUser {
  final String reportReason; // Raporlanan sebep (örneğin: harassment, fraud vb.)
  final String complaintDetails; // Kullanıcının verdiği açıklama
  final String reportedBy; // Raporu yapan kullanıcı ID'si
  final int complaintID; // Her rapor için benzersiz ID
  final String userId; // Raporlanan kullanıcının ID'si

  ReportedUser({
    required this.reportReason,
    required this.complaintDetails,
    required this.reportedBy,
    required this.complaintID,
    required this.userId,
  });

  // Firestore veritabanına kaydederken veri formatını dönüştüren fonksiyon
  Map<String, dynamic> toMap() {
    return {
      'reportReason': reportReason,
      'complaintDetails': complaintDetails,
      'reportedBy': reportedBy,
      'complaintID': complaintID,
      'userId': userId,
    };
  }

  // Firestore'dan alınan veriyi modele dönüştürme fonksiyonu
  factory ReportedUser.fromMap(Map<String, dynamic> map) {
    return ReportedUser(
      reportReason: map['reportReason'],
      complaintDetails: map['complaintDetails'],
      reportedBy: map['reportedBy'],
      complaintID: map['complaintID'],
      userId: map['userId'],
    );
  }
}
