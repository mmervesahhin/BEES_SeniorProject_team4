import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reported_request_model.dart';

class ReportedRequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının aynı request'i daha önce rapor edip etmediğini kontrol et
  Future<bool> hasUserReportedRequest(String requestId, String userId) async {
    final reportQuery = await _firestore
        .collection('reported_requests')
        .where('requestId', isEqualTo: requestId)
        .where('reportedBy', isEqualTo: userId)
        .get();

    return reportQuery.docs.isNotEmpty;
  }

  // Request raporunu Firestore'a kaydet
  Future<void> reportRequest(ReportedRequest reportedRequest) async {
    try {
      await _firestore.collection('reported_requests').add(reportedRequest.toMap());
    } catch (e) {
      print("Error reporting request: $e");
      throw e;
    }
  }
}
