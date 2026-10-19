import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ai_checker/features/auth/presentation/providers/auth_provider.dart';
import 'package:ai_checker/features/auth/presentation/screens/login_screen.dart';
import 'package:ai_checker/features/editor/presentation/providers/editor_provider.dart';
import 'package:ai_checker/features/editor/presentation/screens/editor_screen.dart';

void main() {
  testWidgets('Login screen smoke test renders fields and button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('EditorScreen renders canvas and app bar without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EditorProvider()),
        ],
        child: const MaterialApp(
          home: EditorScreen(),
        ),
      ),
    );

    expect(find.text('AI DOC'), findsOneWidget);
    expect(find.text('Untitled Document'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
