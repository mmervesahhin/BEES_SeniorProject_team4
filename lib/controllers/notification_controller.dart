// 📍 notification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genel yapı: Bildirim Firestore'da 'notifications' koleksiyonuna kaydedilir
  Future<void> _sendNotification({
    required String receiverId,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'receiverId': receiverId,
        'message': message,
        'type': type,
        'timestamp': DateTime.now(),
        'isRead': false,
      });
      print("📩 Bildirim gönderildi: $message");
    } catch (e) {
      print("❌ Bildirim gönderilemedi: $e");
    }
  }

  /// 🎯 Favoriye eklendiğinde çağır
  Future<void> sendFavoriteNotification(String itemOwnerId, String itemTitle) async {
    await _sendNotification(
      receiverId: itemOwnerId,
      message: "Your item '$itemTitle' has been added to favorites.",
      type: 'favorite',
    );
  }

  /// 💬 Yeni mesaj geldiğinde çağır
  Future<void> sendMessageNotification(String receiverId, String senderName) async {
    await _sendNotification(
      receiverId: receiverId,
      message: "You have a new message from $senderName.",
      type: 'message',
    );
  }

  /// 💸 Favori item fiyatı düştüğünde
  Future<void> sendPriceDropNotification(String userId, String itemTitle) async {
    await _sendNotification(
      receiverId: userId,
      message: "Price dropped for item '$itemTitle'.",
      type: 'price_drop',
    );
  }

  /// ✅ Item BEESED olduğunda favori kullanıcıya bildir
  Future<void> sendBeeesedNotification(String userId, String itemTitle) async {
    await _sendNotification(
      receiverId: userId,
      message: "The item '$itemTitle' has been BEESED.",
      type: 'item_beesed',
    );
  }

  /// 📅 30 gündür etkileşim olmayan item için hatırlatma
  Future<void> sendInactivityReminder(String ownerId, String itemTitle) async {
    await _sendNotification(
      receiverId: ownerId,
      message: "Reminder: No interaction with your item '$itemTitle' for 30 days.",
      type: 'reminder',
    );
  }

  /// ⭐ Değerlendirme bildirimi
  Future<void> sendRatingReminder(String buyerId, String itemTitle) async {
    await _sendNotification(
      receiverId: buyerId,
      message: "Please rate your experience for the item '$itemTitle'.",
      type: 'rating',
    );
  }
}
