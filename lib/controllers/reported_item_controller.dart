import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reported_item_model.dart';

class ReportedItemController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının aynı item'ı daha önce rapor edip etmediğini kontrol et
  Future<bool> hasUserReportedItem(String itemId, String userId) async {
    final reportQuery = await _firestore
        .collection('reported_items') // 'reported_items' koleksiyonunu kullanıyoruz
        .where('itemID', isEqualTo: itemId) // itemID ile arama yapıyoruz
        .where('reportedBy', isEqualTo: userId) // reportedBy (userID) ile arama yapıyoruz
        .get();

    return reportQuery.docs.isNotEmpty; // Eğer rapor varsa true döner
  }

  // Raporu Firestore'a kaydetme fonksiyonu
  Future<void> reportItem(ReportedItem reportedItem) async {
    try {
      // Firestore'da 'reported_items' koleksiyonuna yeni bir belge ekliyoruz
      await _firestore.collection('reported_items').add(reportedItem.toMap());
    } catch (e) {
      print("Error reporting item: $e");
      throw e;
    }
  }


  

  // // Örneğin, bir complaintID ile daha önce raporlanan item'ları getirme fonksiyonu (isteğe bağlı - admin için ilerde kullanılabilir.)
  // Future<List<ReportedItem>> getReportedItems() async {
  //   try {
  //     QuerySnapshot snapshot = await _firestore.collection('reported_items').get();
  //     return snapshot.docs.map((doc) {
  //       return ReportedItem.fromMap(doc.data() as Map<String, dynamic>);
  //     }).toList();
  //   } catch (e) {
  //     print("Error fetching reported items: $e");
  //     return [];
  //   }
  // }

Future<bool> checkIfAlreadyReported(String userId, String itemId) async {
  try {
    print("Checking if already reported - UserID: $userId, ItemID: $itemId");

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('reported_items')
        .where('reportedBy', isEqualTo: userId)
        .where('itemId', isEqualTo: itemId)
        .get();

    print("Query Result: ${querySnapshot.docs.length} records found");

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print("Error in checkIfAlreadyReported: $e");
    return false; // Hata olursa false dönelim ki sistemi bozmasın
  }
}

// Kullanıcının yaptığı raporu iptal etme fonksiyonu - buna daha sonra bakacağım.
Future<void> deleteReport(String itemId, String userId) async {
  try {
    // Kullanıcının yaptığı raporu Firestore'dan bul
    QuerySnapshot querySnapshot = await _firestore
        .collection('reported_items')
        .where('itemID', isEqualTo: itemId)
        .where('reportedBy', isEqualTo: userId)
        .get();

    // Eğer rapor bulunursa, sil
    for (var doc in querySnapshot.docs) {
      await _firestore.collection('reported_items').doc(doc.id).delete();
    }
  } catch (e) {
    print("Error canceling report: $e");
    throw e;
  }
}
}
