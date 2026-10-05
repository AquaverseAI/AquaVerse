import 'package:flutter_test/flutter_test.dart';
import 'package:aquaverse_farmer_app/core/router/route_guard.dart';

void main() {
  group('RouteGuard — Unauthenticated Access Control', () {
    test('Public and onboarding routes are accessible without session', () async {
      final guard = RouteGuard(
        hasSession: () async => false,
        getVerifiedRole: () async => null,
        hasOnboarded: () async => false,
      );

      expect(await guard.redirect('/'), isNull);
      expect(await guard.redirect('/login'), isNull);
      expect(await guard.redirect('/onboarding/language'), isNull);
      expect(await guard.redirect('/onboarding/role'), isNull);
      expect(await guard.redirect('/onboarding/mobile'), isNull);
      expect(await guard.redirect('/onboarding/otp'), isNull);
    });

    test('Protected farmer route is blocked when unauthenticated and not onboarded -> /onboarding/language', () async {
      final guard = RouteGuard(
        hasSession: () async => false,
        getVerifiedRole: () async => null,
        hasOnboarded: () async => false,
      );

      expect(await guard.redirect('/today'), '/onboarding/language');
      expect(await guard.redirect('/log'), '/onboarding/language');
      expect(await guard.redirect('/ask'), '/onboarding/language');
      expect(await guard.redirect('/alerts'), '/onboarding/language');
    });

    test('Protected farmer route is blocked when unauthenticated and onboarded -> /onboarding/role', () async {
      final guard = RouteGuard(
        hasSession: () async => false,
        getVerifiedRole: () async => null,
        hasOnboarded: () async => true,
      );

      expect(await guard.redirect('/today'), '/onboarding/role');
      expect(await guard.redirect('/profile'), '/onboarding/role');
    });

    test('Protected officer route is blocked when unauthenticated -> /onboarding/role', () async {
      final guard = RouteGuard(
        hasSession: () async => false,
        getVerifiedRole: () async => null,
        hasOnboarded: () async => true,
      );

      expect(await guard.redirect('/officer/dashboard'), '/onboarding/role');
      expect(await guard.redirect('/officer/visit-log'), '/onboarding/role');
    });
  });

  group('RouteGuard — Role-Based Authorization', () {
    test('Farmer role allows Farmer routes and blocks Officer routes', () async {
      final guard = RouteGuard(
        hasSession: () async => true,
        getVerifiedRole: () async => 'farmer',
        hasOnboarded: () async => true,
      );

      // Farmer routes allowed
      expect(await guard.redirect('/today'), isNull);
      expect(await guard.redirect('/log'), isNull);
      expect(await guard.redirect('/ask'), isNull);
      expect(await guard.redirect('/alerts'), isNull);
      expect(await guard.redirect('/crop'), isNull);
      expect(await guard.redirect('/ponds'), isNull);

      // Officer routes blocked -> redirected to /today
      expect(await guard.redirect('/officer/dashboard'), '/today');
      expect(await guard.redirect('/officer/visit-log'), '/today');
      expect(await guard.redirect('/officer/profile'), '/today');
    });

    test('Officer role allows Officer routes and blocks Farmer-only routes', () async {
      final guard = RouteGuard(
        hasSession: () async => true,
        getVerifiedRole: () async => 'officer',
        hasOnboarded: () async => true,
      );

      // Officer routes allowed
      expect(await guard.redirect('/officer/dashboard'), isNull);
      expect(await guard.redirect('/officer/visit-log'), isNull);
      expect(await guard.redirect('/officer/profile'), isNull);

      // Farmer-only routes blocked -> redirected to /officer/dashboard
      expect(await guard.redirect('/today'), '/officer/dashboard');
      expect(await guard.redirect('/log'), '/officer/dashboard');
      expect(await guard.redirect('/ask'), '/officer/dashboard');
      expect(await guard.redirect('/alerts'), '/officer/dashboard');
      expect(await guard.redirect('/crop'), '/officer/dashboard');
      expect(await guard.redirect('/ponds'), '/officer/dashboard');
    });

    test('Authenticated user with missing or unknown role is redirected to safe re-login', () async {
      final guardNullRole = RouteGuard(
        hasSession: () async => true,
        getVerifiedRole: () async => null,
        hasOnboarded: () async => true,
      );
      expect(await guardNullRole.redirect('/today'), '/onboarding/role');

      final guardUnknownRole = RouteGuard(
        hasSession: () async => true,
        getVerifiedRole: () async => 'superadmin',
        hasOnboarded: () async => true,
      );
      expect(await guardUnknownRole.redirect('/officer/dashboard'), '/onboarding/role');
    });
  });

  group('RouteGuard — Backend Role Authority Negative Tests', () {
    test('Backend verified role is Farmer even if client intended Officer', () async {
      // Regardless of what user selected in UI, verifiedRole is 'farmer'
      final guard = RouteGuard(
        hasSession: () async => true,
        getVerifiedRole: () async => 'farmer',
        hasOnboarded: () async => true,
      );

      // Must NOT be allowed to access officer dashboard
      expect(await guard.redirect('/officer/dashboard'), '/today');
      // Allowed to access today
      expect(await guard.redirect('/today'), isNull);
    });

    test('Backend verified role is Officer even if client intended Farmer', () async {
      // Regardless of what user selected in UI, verifiedRole is 'officer'
      final guard = RouteGuard(
        hasSession: () async => true,
        getVerifiedRole: () async => 'officer',
        hasOnboarded: () async => true,
      );

      // Must NOT be allowed to access farmer today
      expect(await guard.redirect('/today'), '/officer/dashboard');
      // Allowed to access officer dashboard
      expect(await guard.redirect('/officer/dashboard'), isNull);
    });
  });
}

