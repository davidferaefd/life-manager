// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_manager/main.dart';

void main() {
  testWidgets('navega entre as abas principais', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeManagerApp());
    await tester.pumpAndSettle();

    expect(find.text('Rotina de hoje'), findsOneWidget);
    expect(find.text('Dia livre por enquanto'), findsOneWidget);

    await tester.tap(find.text('Estudos'));
    await tester.pumpAndSettle();
    expect(find.text('Sessão de foco'), findsOneWidget);
    expect(find.text('Seu plano começa aqui'), findsOneWidget);

    await tester.tap(find.text('Trabalho'));
    await tester.pumpAndSettle();
    expect(find.text('Seu quadro está vazio'), findsOneWidget);

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();
    expect(find.text('Constância · últimos 30 dias'), findsOneWidget);
  });

  testWidgets('cria rotina doméstica e concede XP ao concluir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LifeManagerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Organizar cozinha');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Organizar cozinha'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();
    expect(find.text('10 XP acumulados'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });
}
