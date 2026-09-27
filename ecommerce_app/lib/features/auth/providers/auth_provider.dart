import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/user.dart';

/// Whether the stored session has been read back yet.
///
/// The router must not redirect while this is [restoring], otherwise a page
/// reload flings a signed-in owner to `/login` for a frame and back again.
enum AuthStatus { restoring, signedOut, signedIn }

/// Sign-in, registration and session handling for both roles.
///
/// This is deliberately transport-free: it validates what the user typed,
/// remembers who is signed in, and lets the router enforce the role's route
/// prefix. The OTP flow mirrors a real SMS backend (issue, then verify) so a
/// real gateway can be dropped in later without touching the UI.
class AuthProvider extends ChangeNotifier {
  AuthProvider();

  static const String _kUser = 'auth_session_user';
  static const String _kPendingPhone = 'auth_pending_phone';

  /// Accepts any correctly-formed phone, so the demo never dead-ends behind a
  /// real SMS gateway that does not exist yet.
  static const String demoOtp = '123456';

  AuthStatus _status = AuthStatus.restoring;
  AppUser? _user;
  String? _pendingPhone;
  String? _pendingOtp;

  Future<void> _pendingWrite = Future<void>.value();
  bool _disposed = false;

  // ------------------------------------------------------------------ state

  AuthStatus get status => _status;
  bool get isRestoring => _status == AuthStatus.restoring;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  AppUser? get user => _user;
  UserRole? get role => _user?.role;
  String? get pendingPhone => _pendingPhone;
  String? get pendingOtp => _pendingOtp;

  /// Where a signed-in user of the current role belongs.
  String get homePath => role?.homePath ?? '/login';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Completes once every queued write has reached disk, for tests.
  Future<void> flush() => _pendingWrite;

  // -------------------------------------------------------------- validation

  /// Normalises `+91 98765 43210` to `9876543210`.
  static String normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^91(?=\d{10}$)'), '');

  // Validators take a nullable value so they can be handed straight to
  // `FormField.validator`, which passes null before anything is typed.
  static String? validatePhone(String? raw) {
    final digits = normalizePhone(raw ?? '');
    if (digits.isEmpty) return 'Enter your phone number';
    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Mobile numbers start with 6, 7, 8 or 9';
    }
    return null;
  }

  static String? validateName(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your name';
    if (value.length < 2) return 'Name looks too short';
    if (value.length > 60) return 'Name is too long';
    return null;
  }

  static String? validateShopName(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your shop name';
    if (value.length < 2) return 'Shop name looks too short';
    return null;
  }

  /// Email is optional, but it has to be right when supplied.
  static String? validateEmail(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateOtp(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter the 6-digit code';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'The code is 6 digits';
    return null;
  }

  // ----------------------------------------------------------------- sign in

  /// Starts the OTP flow. Returns an error message, or null on success.
  String? sendOtp(String phone) {
    final error = validatePhone(phone);
    if (error != null) return error;

    _pendingPhone = normalizePhone(phone);
    _pendingOtp = demoOtp;
    notifyListeners();
    return null;
  }

  /// Verifies the code and signs the account in for [role].
  ///
  /// A demo account is issued on the spot, which keeps role switching easy
  /// without pretending a backend exists.
  String? verifyOtp(String phone, String otp, {UserRole role = UserRole.customer}) {
    final phoneError = validatePhone(phone);
    if (phoneError != null) return phoneError;

    final otpError = validateOtp(otp);
    if (otpError != null) return otpError;

    final normalized = normalizePhone(phone);
    if (_pendingPhone != normalized) {
      return 'Request a new code for this number';
    }
    if (otp.trim() != _pendingOtp) {
      return 'That code is not correct';
    }

    final user = AppUser(
      id: 'u-$normalized',
      name: role == UserRole.owner ? 'Shop Owner' : 'Customer',
      email: '',
      phone: normalized,
      role: role,
      shopName: role == UserRole.owner ? 'My Shop' : null,
    );
    return _signIn(user);
  }

  /// Registers an account and signs it in immediately.
  String? register({
    required String name,
    String email = '',
    required String phone,
    required UserRole role,
    String? shopName,
    String address = '',
  }) {
    final nameError = validateName(name);
    if (nameError != null) return nameError;

    final emailError = validateEmail(email);
    if (emailError != null) return emailError;

    final phoneError = validatePhone(phone);
    if (phoneError != null) return phoneError;

    if (role == UserRole.owner) {
      final shopError = validateShopName(shopName ?? '');
      if (shopError != null) return shopError;
    }

    final normalized = normalizePhone(phone);
    final user = AppUser(
      id: 'u-$normalized',
      name: name.trim(),
      email: email.trim(),
      phone: normalized,
      role: role,
      shopName: role == UserRole.owner ? shopName?.trim() : null,
    );
    return _signIn(user);
  }

  /// Signs in without a password so the role switch can be demonstrated.
  String? signInAsDemo(UserRole role) {
    final normalized = '9${(Random().nextInt(900000000) + 100000000)}';
    return _signIn(AppUser(
      id: 'u-$normalized',
      name: role == UserRole.owner ? 'Shop Owner' : 'Customer',
      email: '',
      phone: normalized,
      role: role,
      shopName: role == UserRole.owner ? 'Demo Store' : null,
    ));
  }

  /// Applies a signed-in session. Returns null so it can be handed back from
  /// the sign-in methods as their "error" result.
  String? _signIn(AppUser user) {
    _user = user;
    _pendingPhone = null;
    _pendingOtp = null;
    _status = AuthStatus.signedIn;
    _persist();
    notifyListeners();
    return null;
  }

  /// Ends the session and returns to the sign-in screen.
  Future<void> signOut() async {
    _user = null;
    _pendingPhone = null;
    _pendingOtp = null;
    _status = AuthStatus.signedOut;
    _forget();
    notifyListeners();
  }

  // ------------------------------------------------------------ persistence

  /// Reads a stored session back, if there is one.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUser);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, Object?>;
        _user = AppUser.fromJson(json);
        _status = AuthStatus.signedIn;
      } else {
        _status = AuthStatus.signedOut;
      }
      _pendingPhone = prefs.getString(_kPendingPhone);
    } catch (_) {
      _user = null;
      _status = AuthStatus.signedOut;
    }
    if (!_disposed) notifyListeners();
  }

  void _persist() {
    final snapshot = _user;
    final phone = _pendingPhone;
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (snapshot != null) {
          await prefs.setString(_kUser, jsonEncode(snapshot.toJson()));
        } else {
          await prefs.remove(_kUser);
        }
        if (phone != null) {
          await prefs.setString(_kPendingPhone, phone);
        } else {
          await prefs.remove(_kPendingPhone);
        }
      } catch (_) {}
    });
  }

  void _forget() {
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kUser);
        await prefs.remove(_kPendingPhone);
      } catch (_) {}
    });
  }
}
