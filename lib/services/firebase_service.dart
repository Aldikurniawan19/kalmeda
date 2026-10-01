import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized service for Firebase initialization and instance management.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  FirebaseService._internal();

  /// Initialize Firebase app.
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  /// Singleton Firebase Auth instance.
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Singleton Cloud Firestore instance.
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
