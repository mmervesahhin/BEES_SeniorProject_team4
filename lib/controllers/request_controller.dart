import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:bees/models/request_model.dart';


class RequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = "requests";

  Future<void> createRequest(Request request) async {
  try {
    DocumentReference docRef = _firestore.collection(collectionPath).doc(); // Firestore’un otomatik ID üretmesini sağla
    String generatedID = docRef.id; // Oluşturulan ID’yi al

    Request newRequest = Request(
      requestID: generatedID, // Firestore'un oluşturduğu ID'yi ata
      requestOwnerID: request.requestOwnerID,
      requestContent: request.requestContent,
      requestStatus: request.requestStatus,
      creationDate: request.creationDate,
    );

    await docRef.set(newRequest.toJson()); // Veriyi kaydet

    print("Request created with ID: $generatedID"); // ID’yi terminalde göster
  } catch (e) {
    print("Error creating request: $e");
  }
}


  // Tüm istekleri getirme
  Stream<List<Request>> getRequests() {
    return _firestore.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Request.fromJson(doc.data())).toList();
    });
  }

  // Belirli bir isteği getirme
  Future<Request?> getRequestById(String requestID) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collectionPath).doc(requestID).get();
      if (doc.exists) {
        return Request.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error getting request: \$e");
    }
    return null;
  }

 
}
