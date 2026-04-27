import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/seed_service.dart';
import '../services/session_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  late final SeedService _seedService;
  Timer? _sessionTimer;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController(Isar isar) {
    _seedService = SeedService(isar);
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> checkAndRestoreSession() async {
    final isSessionValid = await SessionService.isSessionValid();
    if (!isSessionValid) {
      _sessionTimer?.cancel();
      await SessionService.clearSession();
      _currentUser = null;
      notifyListeners();
      return false;
    }

    final sessionData = await SessionService.getSessionData();
    final firebaseUser = _authService.currentUser;

    if (firebaseUser != null) {
      _currentUser = UserModel.fromFirebase(firebaseUser);
    } else if (sessionData['uid'] != null && sessionData['email'] != null) {
      _currentUser = UserModel(
        uid: sessionData['uid']!,
        email: sessionData['email']!,
        name: sessionData['name'] ?? '',
      );
    } else {
      _sessionTimer?.cancel();
      await SessionService.clearSession();
      _currentUser = null;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> startSessionTimer() async {
    _sessionTimer?.cancel();

    final remainingMinutes = await SessionService.getRemainingMinutes();
    if (remainingMinutes <= 0) {
      await logout();
      return;
    }

    _sessionTimer = Timer(Duration(minutes: remainingMinutes), () {
      unawaited(logout());
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService
          .login(email.trim(), password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Koneksi timeout. Periksa internet kamu.');
            },
          );

      if (_currentUser != null) {
        try {
          await _seedService.seedAll(_currentUser!.uid);
        } catch (e) {
          // ignore: avoid_print
          print('Seed error (non-fatal): $e');
        }

        await SessionService.saveSession(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          name: _currentUser!.name,
        );
        await startSessionTimer();
      }

      notifyListeners();
      return true;
    } on Exception catch (e) {
      _setError(_parseFirebaseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService
          .register(email.trim(), password, name.trim())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Koneksi timeout. Periksa internet kamu.');
            },
          );

      if (_currentUser != null) {
        try {
          await _seedService.seedAll(_currentUser!.uid);
        } catch (e) {
          // ignore: avoid_print
          print('Seed error (non-fatal): $e');
        }

        await SessionService.saveSession(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          name: _currentUser!.name,
        );
        await startSessionTimer();
      }

      notifyListeners();
      return true;
    } on Exception catch (e) {
      _setError(_parseFirebaseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      _sessionTimer?.cancel();
      await SessionService.clearSession();
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Gagal logout. Silakan coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  String _parseFirebaseError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) {
      return 'Koneksi timeout. Periksa internet kamu.';
    }
    if (msg.contains('user-not-found') || msg.contains('invalid-credential')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('wrong-password')) {
      return 'Password salah.';
    }
    if (msg.contains('email-already')) {
      return 'Email sudah digunakan.';
    }
    if (msg.contains('weak-password')) {
      return 'Password minimal 6 karakter.';
    }
    if (msg.contains('network-request-failed') || msg.contains('network')) {
      return 'Tidak ada koneksi internet.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
    if (msg.contains('configuration-not-found') ||
        msg.contains('configuration_not_found')) {
      return 'Konfigurasi Firebase bermasalah.';
    }
    return 'Terjadi kesalahan: ${e.toString()}';
  }
}
