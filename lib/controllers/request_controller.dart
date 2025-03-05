import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/models/request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/user_model.dart' as bees;

class RequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = "requests";
  final String usersCollectionPath = "users";

  // Kullanıcıları önbelleğe almak için bir map oluştur
  Map<String, bees.User> cachedUsers = {};

  /// **Yeni Request Oluşturma**
  Future<void> createRequest(Request request) async {
    try {
      DocumentReference docRef = _firestore.collection(collectionPath).doc(); // Firestore’un otomatik ID üretmesini sağla
      String generatedID = docRef.id; // Firestore'un ürettiği ID'yi al

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: Kullanıcı giriş yapmamış.');
        return;
      }

      Request newRequest = Request(
        requestID: generatedID,
        requestOwnerID: userId,
        requestContent: request.requestContent,
        requestStatus: request.requestStatus,
        creationDate: request.creationDate,
      );

      await docRef.set(newRequest.toJson()); // Firestore'a kaydet
      print("✅ Request oluşturuldu! ID: $generatedID");

    } catch (e) {
      print("🔥 Request oluşturma hatası: $e");
    }
  }

  /// **Firestore'dan Gerçek Zamanlı Request Alma**
  Stream<List<Request>> getRequests() {
    return _firestore.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Request.fromJson(data);
      }).toList();
    });
  }

  /// **Belirli bir Request’i ID ile Getirme**
  Future<Request?> getRequestById(String requestID) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collectionPath).doc(requestID).get();
      if (doc.exists) {
        return Request.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("🔥 Request alma hatası: $e");
    }
    return null;
  }

  /// **Request'in Sahibini (User) Getir & Önbelleğe Al**
  Future<bees.User?> getUserByRequestID(String requestID) async {
    try {
      print("🔍 Request ID ile kullanıcı aranıyor: $requestID");

      // Request belgesini getir
      DocumentSnapshot requestDoc = await _firestore.collection(collectionPath).doc(requestID).get();

      if (!requestDoc.exists || requestDoc.data() == null) {
        print("🚨 Hata: Bu ID'ye sahip request bulunamadı.");
        return null;
      }

      // Request'ten kullanıcı ID'sini al
      String? userID = requestDoc.get('requestOwnerID');
      if (userID == null || userID.isEmpty) {
        print("🚨 Hata: Request'in sahibi belirlenemedi.");
        return null;
      }

      print("🔍 Kullanıcı ID'si bulundu: $userID");

      // Kullanıcı önbellekte var mı?
      if (cachedUsers.containsKey(userID)) {
        print("✅ Kullanıcı önbellekten getirildi.");
        return cachedUsers[userID];
      }

      // Eğer yoksa Firestore'dan çek
      DocumentSnapshot userDoc = await _firestore.collection(usersCollectionPath).doc(userID).get();
      if (!userDoc.exists || userDoc.data() == null) {
        print("🚨 Hata: Firestore'da bu ID'ye sahip kullanıcı bulunamadı.");
        return null;
      }

      bees.User user = bees.User.fromMap(userDoc.data() as Map<String, dynamic>);

      // Kullanıcıyı önbelleğe al
      cachedUsers[userID] = user;
      print("✅ Kullanıcı Firestore'dan alındı ve önbelleğe kaydedildi.");

      return user;
    } catch (e) {
      print("🔥 Kullanıcı alma hatası: $e");
      return null;
    }
  }
}
