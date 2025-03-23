class ReportedRequest {
  final String requestId;
  final String reportedBy;
  final String reportReason;
  final DateTime reportDate;

  ReportedRequest({
    required this.requestId,
    required this.reportedBy,
    required this.reportReason,
    required this.reportDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'reportedBy': reportedBy,
      'reportReason': reportReason,
      'reportDate': reportDate.toIso8601String(),
    };
  }

  factory ReportedRequest.fromFirestore(Map<String, dynamic> data) {
    return ReportedRequest(
      requestId: data['requestId'],
      reportedBy: data['reportedBy'],
      reportReason: data['reportReason'],
      reportDate: DateTime.parse(data['reportDate']),
    );
  }
}
