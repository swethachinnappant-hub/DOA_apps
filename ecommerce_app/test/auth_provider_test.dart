import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('phone validation', () {
    test('rejects an empty number', () {
      expect(AuthProvider.validatePhone(''), 'Enter your phone number');
      expect(AuthProvider.validatePhone(null), 'Enter your phone number');
    });

    test('rejects a short number', () {
      expect(AuthProvider.validatePhone('98765'), 'Enter a valid 10-digit phone number');
    });

    test('rejects numbers that do not start 6-9', () {
      expect(
        AuthProvider.validatePhone('1234567890'),
        'Mobile numbers start with 6, 7, 8 or 9',
      );
    });

    test('accepts a valid number', () {
      expect(AuthProvider.validatePhone('9876543210'), isNull);
      expect(AuthProvider.validatePhone('6123456789'), isNull);
    });

    test('ignores spaces, dashes and a country code', () {
      expect(AuthProvider.validatePhone('+91 98765-43210'), isNull);
      expect(AuthProvider.normalizePhone('+91 98765 43210'), '9876543210');
      expect(AuthProvider.normalizePhone('9876543210'), '9876543210');
    });

    test('does not strip a 91 that is part of the local number', () {
      expect(AuthProvider.normalizePhone('91987654321'), '91987654321');
    });
  });

  group('other validators', () {
    test('name is required and length bounded', () {
      expect(AuthProvider.validateName(''), 'Enter your name');
      expect(AuthProvider.validateName('   '), 'Enter your name');
      expect(AuthProvider.validateName('A'), 'Name looks too short');
      expect(AuthProvider.validateName('Priya Sharma'), isNull);
      expect(AuthProvider.validateName('a' * 61), 'Name is too long');
    });

    test('shop name is required', () {
      expect(AuthProvider.validateShopName(''), 'Enter your shop name');
      expect(AuthProvider.validateShopName('Chirag Associates'), isNull);
    });

    test('email is optional but must be valid when present', () {
      expect(AuthProvider.validateEmail(''), isNull);
      expect(AuthProvider.validateEmail(null), isNull);
      expect(AuthProvider.validateEmail('a@b.com'), isNull);
      expect(AuthProvider.validateEmail('nope'), 'Enter a valid email address');
      expect(AuthProvider.validateEmail('a@b'), 'Enter a valid email address');
    });

    test('otp must be six digits', () {
      expect(AuthProvider.validateOtp(''), 'Enter the 6-digit code');
      expect(AuthProvider.validateOtp('12345'), 'The code is 6 digits');
      expect(AuthProvider.validateOtp('abcdef'), 'The code is 6 digits');
      expect(AuthProvider.validateOtp('123456'), isNull);
    });
  });

  group('otp sign-in', () {
    test('sending an otp validates the phone first', () {
      final auth = AuthProvider();
      expect(auth.sendOtp('123'), isNotNull);
      expect(auth.pendingPhone, isNull);
    });

    test('a valid phone stores the pending number and code', () {
      final auth = AuthProvider();
      expect(auth.sendOtp('+91 98765 43210'), isNull);
      expect(auth.pendingPhone, '9876543210');
      expect(auth.pendingOtp, AuthProvider.demoOtp);
      expect(auth.isSignedIn, isFalse);
    });

    test('verifying with the wrong code fails', () {
      final auth = AuthProvider();
      auth.sendOtp('9876543210');
      expect(auth.verifyOtp('9876543210', '000000'), isNotNull);
      expect(auth.isSignedIn, isFalse);
    });

    test('verifying with a number that was never sent to fails', () {
      final auth = AuthProvider();
      auth.sendOtp('9876543210');
      expect(auth.verifyOtp('9123456789', AuthProvider.demoOtp), isNotNull);
    });

    test('verifying the right code signs the customer in', () {
      final auth = AuthProvider();
      auth.sendOtp('9876543210');
      final error = auth.verifyOtp('9876543210', AuthProvider.demoOtp);

      expect(error, isNull);
      expect(auth.isSignedIn, isTrue);
      expect(auth.role, UserRole.customer);
      expect(auth.homePath, '/app');
      expect(auth.pendingPhone, isNull);
    });

    test('verifying as an owner lands in the seller console', () {
      final auth = AuthProvider();
      auth.sendOtp('9876543210');
      auth.verifyOtp('9876543210', AuthProvider.demoOtp, role: UserRole.owner);

      expect(auth.role, UserRole.owner);
      expect(auth.homePath, '/owner');
    });
  });

  group('registration', () {
    test('a customer account needs no shop name', () {
      final auth = AuthProvider();
      final error = auth.register(
        name: 'Priya Sharma',
        phone: '9876543210',
        role: UserRole.customer,
      );

      expect(error, isNull);
      expect(auth.isSignedIn, isTrue);
      expect(auth.user?.shopName, isNull);
      expect(auth.user?.phone, '9876543210');
    });

    test('an owner account requires a shop name', () {
      final auth = AuthProvider();
      expect(
        auth.register(
          name: 'Chirag Rao',
          phone: '9876543210',
          role: UserRole.owner,
        ),
        'Enter your shop name',
      );
      expect(auth.isSignedIn, isFalse);

      expect(
        auth.register(
          name: 'Chirag Rao',
          phone: '9876543210',
          role: UserRole.owner,
          shopName: 'Chirag Associates',
        ),
        isNull,
      );
      expect(auth.isSignedIn, isTrue);
      expect(auth.role, UserRole.owner);
      expect(auth.user?.shopName, 'Chirag Associates');
    });

    test('invalid fields stop registration', () {
      final auth = AuthProvider();
      expect(
        auth.register(name: '', phone: '9876543210', role: UserRole.customer),
        'Enter your name',
      );
      expect(
        auth.register(
          name: 'Priya',
          phone: '9876543210',
          email: 'bad',
          role: UserRole.customer,
        ),
        'Enter a valid email address',
      );
      expect(
        auth.register(name: 'Priya', phone: '123', role: UserRole.customer),
        'Enter a valid 10-digit phone number',
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('an owner display name prefers the shop name', () {
      final auth = AuthProvider();
      auth.register(
        name: 'Chirag Rao',
        phone: '9876543210',
        role: UserRole.owner,
        shopName: 'Chirag Associates',
      );

      expect(auth.user?.displayName, 'Chirag Associates');
    });
  });

  group('session persistence', () {
    test('a signed-in session survives a restore', () async {
      final first = AuthProvider();
      first.register(
        name: 'Priya Sharma',
        phone: '9876543210',
        role: UserRole.customer,
      );
      await first.flush();

      final second = AuthProvider();
      expect(second.isRestoring, isTrue);
      await second.restore();

      expect(second.isSignedIn, isTrue);
      expect(second.role, UserRole.customer);
      expect(second.user?.name, 'Priya Sharma');
      expect(second.homePath, '/app');
    });

    test('an owner session restores to the seller console', () async {
      final first = AuthProvider();
      first.register(
        name: 'Chirag Rao',
        phone: '9876543210',
        role: UserRole.owner,
        shopName: 'Chirag Associates',
      );
      await first.flush();

      final second = AuthProvider();
      await second.restore();

      expect(second.role, UserRole.owner);
      expect(second.homePath, '/owner');
      expect(second.user?.shopName, 'Chirag Associates');
    });

    test('signing out clears the stored session', () async {
      final auth = AuthProvider();
      auth.signInAsDemo(UserRole.owner);
      await auth.flush();
      expect(auth.isSignedIn, isTrue);

      await auth.signOut();
      await auth.flush();

      expect(auth.isSignedIn, isFalse);
      expect(auth.homePath, '/login');

      final restored = AuthProvider();
      await restored.restore();
      expect(restored.isSignedIn, isFalse);
    });

    test('a restored profile is signed out when nothing is stored', () async {
      final auth = AuthProvider();
      await auth.restore();

      expect(auth.isRestoring, isFalse);
      expect(auth.isSignedIn, isFalse);
      expect(auth.role, isNull);
    });

    test('a corrupt stored session falls back to signed out', () async {
      SharedPreferences.setMockInitialValues({
        'auth_session_user': 'not-json',
      });
      final auth = AuthProvider();
      await auth.restore();

      expect(auth.isSignedIn, isFalse);
      expect(auth.role, isNull);
    });
  });

  group('role destinations', () {
    test('the two roles go to different homes', () {
      expect(UserRole.customer.homePath, '/app');
      expect(UserRole.owner.homePath, '/owner');
      expect(UserRole.customer.routePrefix, '/app');
      expect(UserRole.owner.routePrefix, '/owner');
    });

    test('an unknown role name falls back to customer', () {
      expect(UserRole.fromName('owner'), UserRole.owner);
      expect(UserRole.fromName('nonsense'), UserRole.customer);
      expect(UserRole.fromName(null), UserRole.customer);
    });
  });
}
