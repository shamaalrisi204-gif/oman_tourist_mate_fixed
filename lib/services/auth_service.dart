// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  final _db = FirebaseFirestore.instance;

  /// تسجيل جديد بإيميل + باسوورد

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // إرسال إيميل تحقق (لو تحبين تستخدمينه مع OTP الحالي)

    try {
      await cred.user?.sendEmailVerification();
    } catch (_) {}

    return cred;
  }

  /// حفظ بيانات السائح في Firestore (users collection)

  Future<void> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required bool emailVerified,
  }) async {
    final profile = UserProfile(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      emailVerified: emailVerified,
    );

    await _db.collection('users').doc(uid).set(
          profile.toMap()..['createdAt'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true),
        );
  }

  /// تسجيل دخول

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return cred;
  }

  /// جلب بروفايل المستخدم الحالي من Firestore

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) return null;

    return UserProfile.fromMap(doc.data()!);
  }
}
