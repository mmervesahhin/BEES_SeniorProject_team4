import 'package:bees/controllers/blocked_user_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/models/request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/models/user_model.dart' as bees;
import 'package:firebase_auth/firebase_auth.dart' as auth;


class RequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = "requests";
final String usersCollectionPath = "users";
  Future<void> createRequest(Request request) async {
  try {
    DocumentReference docRef = _firestore.collection(collectionPath).doc(); // Firestore’un otomatik ID üretmesini sağla
    String generatedID = docRef.id; // Oluşturulan ID’yi al

    String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Error: User is not logged in.');
        return;
      }

    Request newRequest = Request(
      requestID: generatedID, // Firestore'un oluşturduğu ID'yi ata
      requestOwnerID: userId,
      requestContent: request.requestContent,
      requestStatus: request.requestStatus,
      creationDate: request.creationDate,
      
    );
   


    // Request newRequest = Request(
    //     requestID: generatedID,
    //     requestOwnerID: currentUser.uid,
    //     // requestOwnerName: currentUser.displayName ?? "Unknown User", // Store user's name
    //     // requestOwnerProfilePic: currentUser.photoURL ?? "", // Store profile picture if available
    //     requestContent: request.requestContent,
    //     requestStatus: request.requestStatus,
    //     creationDate: request.creationDate, // Firestore timestamp
    //   );

    await docRef.set(newRequest.toJson()); // Veriyi kaydet

    print("Request created with ID: $generatedID"); // ID’yi terminalde göster
  } catch (e) {
    print("Error creating request: $e");
  }
}


   // 🔥 Firestore'dan canlı veri almak için güncellenmiş metod:
  // Stream<List<Request>> getRequests() {
  //   return _firestore.collection(collectionPath).snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       final data = doc.data() as Map<String, dynamic>;
  //       return Request.fromJson(data);
  //     }).toList();
  //   });
  // } kodun eski hali, olur da bir şeyleri bozmuşsam burdan eski haline getirelim.
Stream<List<Request>> getRequests(String currentUserId) {
  return _firestore.collection('requests').snapshots().asyncMap((snapshot) async {
    List<Request> requests = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final request = Request.fromJson(data);

      // Engellenen kişinin requestlerini filtrelemek için Firestore'dan kontrol ediyoruz
      DocumentSnapshot blockerDoc = await _firestore
          .collection('blocked_users')
          .doc(currentUserId) // Request sahibinin engellediği kişiler
          .collection('blockers')
          .doc(request.requestOwnerID) // Bu kullanıcıyı engelledi mi?
          .get();


          DocumentSnapshot blockerDoc2 = await _firestore
                    .collection('blocked_users')
                    .doc(request.requestOwnerID)
                    .collection('blockers')
                    .doc(currentUserId)
                    .get();
      // Eğer requestOwnerID, currentUserId tarafından engellenmişse ekleme
      if (!blockerDoc.exists && !blockerDoc2.exists) {
        requests.add(request);
      }
    }

    return requests;
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
  Future<bees.User?> getUserByRequestID(String requestID) async {
  try {
    print("🔍 Fetching request with ID: $requestID");

    // Step 1: Get request document
    DocumentSnapshot requestDoc =
        await _firestore.collection("requests").doc(requestID).get();

    if (!requestDoc.exists || requestDoc.data() == null) {
      print("🚨 Request not found for ID: $requestID");
      return null;
    }

    // Step 2: Get requestOwnerID from request data
    String? userID = requestDoc.get('requestOwnerID');
    if (userID == null || userID.isEmpty) {
      print("🚨 Request has no valid owner ID.");
      return null;
    }

    print("🔍 Request belongs to User ID: $userID");

    // Step 3: Get user document using userID
    DocumentSnapshot userDoc =
        await _firestore.collection("users").doc(userID).get();

    if (!userDoc.exists || userDoc.data() == null) {
      print("🚨 User not found in Firestore for ID: $userID");
      return null;
    }

    print("✅ User data found: ${userDoc.data()}");

    // Step 4: Convert Firestore data to User object
    return bees.User.fromMap(userDoc.data() as Map<String, dynamic>);
  } catch (e) {
    print("🔥 Error fetching user by request ID: $e");
    return null;
  }
}

 
}
