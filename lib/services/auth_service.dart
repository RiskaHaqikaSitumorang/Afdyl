import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> register(String email, String username, String password) async {
    try {
      // Cek username sudah ada atau belum
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();
      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Nama pengguna sudah terdaftar');
      }

      // Buat akun Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data ke Firestore
      UserModel user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        username: username,
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set(user.toMap());

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> login(String usernameOrEmail, String password) async {
    try {
      String email;

      // Jika input mengandung '@' → dianggap email
      if (usernameOrEmail.contains('@')) {
        email = usernameOrEmail;
      } else {
        // Jika input dianggap username → cari email di Firestore
        QuerySnapshot query = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail.toLowerCase())
            .get();

        if (query.docs.isEmpty) {
          throw Exception('Nama pengguna tidak ditemukan');
        }

        email = query.docs.first['email'];
      }

      // Login pakai email + password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil data user dari Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userCredential.user!.uid).get();

      return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userCredential.user!.uid,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Gagal mengirim email reset: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
