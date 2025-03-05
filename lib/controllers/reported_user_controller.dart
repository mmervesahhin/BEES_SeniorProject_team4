import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/models/reported_user_model.dart';

class ReportedUserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni bir rapor eklemek için fonksiyon
  Future<void> addReport(ReportedUser report) async {
    try {
      // Firestore'da 'reported_users' koleksiyonuna yeni raporu ekliyoruz
      await _firestore.collection('reported_users').add(report.toMap());
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }

  // Bir kullanıcının daha önce raporlanıp raporlanmadığını kontrol etme fonksiyonu
  Future<bool> isUserReported(String userId, String reportedBy) async {
    try {
      var querySnapshot = await _firestore
          .collection('reported_users')
          .where('userId', isEqualTo: userId)
          .where('reportedBy', isEqualTo: reportedBy)
          .get();
      
      // Eğer kullanıcı daha önce raporlandıysa, querySnapshot.docs sayısı 1'den büyük olur
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check report status: $e');
    }
  }

  // Tüm raporları almak için fonksiyon
  Future<List<ReportedUser>> getReports() async {
    try {
      var querySnapshot = await _firestore.collection('reported_users').get();
      return querySnapshot.docs
          .map((doc) => ReportedUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }
}
