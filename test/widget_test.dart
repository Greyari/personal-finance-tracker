import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_finance_app/main.dart';

class FakeAuthController extends StateNotifier<AsyncValue<void>>
    implements AuthController {
  FakeAuthController() : super(const AsyncValue.data(null));

  @override
  Future<bool> signIn({required String email, required String password}) async =>
      true;

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      true;

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async => true;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Renders LoginScreen when user is not authenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: AuthGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk untuk mengelola keuangan Anda'), findsOneWidget);
  });
}
