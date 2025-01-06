import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcıyı giriş yapmaya yönlendiren fonksiyon
Future<String> handleLogin(String email, String password) async {
  try {
    // E-posta ve şifre ile giriş yapmayı dene
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    // Başarılı giriş
    return 'Login successful.';
  } on FirebaseAuthException catch (e) {
    // Hata durumları için uygun mesajlar
    if (e.code == 'wrong-password') {
      return 'Invalid password.';
    }
    if (e.code == 'user-not-found') {
      return 'Email is not registered.';
    }
    return 'An unexpected error occurred. Please try again.';
  } catch (e) {
    return 'An unexpected error occurred. Please try again.';
  }
}


  // E-posta adresinin kayıtlı olup olmadığını kontrol eden fonksiyon
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Şifresi doğru olmasa da e-posta doğrulaması yapmak için giriş denemesi yapıyoruz
      await _auth.signInWithEmailAndPassword(email: email, password: 'dummyPassword');
      return true; // Eğer giriş yapabilirse, e-posta kayıtlıdır
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return false; // Eğer kullanıcı bulunmazsa, e-posta kayıtlı değildir
      }
      return false; // Diğer hatalar için de false dönebiliriz
    } catch (e) {
      return false; // Diğer beklenmedik hatalar için de false dönebiliriz
    }
  }

  // Şifrenin doğru olup olmadığını kontrol eden fonksiyon
  Future<bool> isPasswordCorrect(String email, String password) async {
    try {
      // E-posta ve şifre ile giriş yapmayı dene
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true; // Şifre doğru
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return false; // Şifre yanlış
      }
      rethrow; // Diğer hatalar için yeniden hata fırlat
    }
  }

  // Yeni kullanıcı kaydını işleme fonksiyonu (isteğe bağlı)
  Future<String> registerUser(String email, String password) async {
    try {
      // Kullanıcı kaydını dene
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return 'User registered successfully.';
    } on FirebaseAuthException catch (e) {
      // Hata durumunda mesaj döner
      if (e.code == 'email-already-in-use') {
        return 'Email is already in use.';
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Çıkış yapmayı sağlayan fonksiyon
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
