// Regressão: fechar uma tela antes da API responder não pode gerar exceção
// (ex.: "setState() called after dispose()"). Com o depurador do VS Code em
// "Uncaught Exceptions", uma exceção dessas pausa o app e parece um travamento.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app_gestao_leiteira/models/models.dart';
import 'package:app_gestao_leiteira/services/api_service.dart';
import 'package:app_gestao_leiteira/views/animal_list_view.dart';
import 'package:app_gestao_leiteira/views/dashboard_view.dart';
import 'package:app_gestao_leiteira/views/expense_list_view.dart';
import 'package:app_gestao_leiteira/views/health_form_view.dart';
import 'package:app_gestao_leiteira/views/health_list_view.dart';
import 'package:app_gestao_leiteira/views/production_form_view.dart';
import 'package:app_gestao_leiteira/views/production_list_view.dart';
import 'package:app_gestao_leiteira/views/reminder_list_view.dart';
import 'package:app_gestao_leiteira/views/stock_list_view.dart';
import 'package:app_gestao_leiteira/views/vaccine_form_view.dart';

void main() {
  final telas = <String, Widget Function()>{
    'Dashboard': () => const DashboardView(),
    'Animais': () => const AnimalListView(),
    'Produção': () => const ProductionListView(),
    'Financeiro': () => const ExpenseListView(),
    'Saúde': () => const HealthListView(),
    'Agenda': () => const ReminderListView(),
    'Estoque': () => const StockListView(),
    'Form produção': () => const ProductionFormView(),
    'Form saúde': () => const HealthFormView(),
    'Form vacina': () => const VaccineFormView(),
  };

  for (final resposta in ['sucesso', 'erro']) {
    for (final tela in telas.entries) {
      testWidgets('${tela.key}: fechar antes da resposta ($resposta)',
          (tester) async {
        // A API só responde quando o teste liberar
        final liberar = Completer<void>();
        ApiService.client = MockClient((_) async {
          await liberar.future;
          return resposta == 'sucesso'
              ? http.Response.bytes(utf8.encode('[]'), 200,
                  headers: {'content-type': 'application/json'})
              : http.Response('{"message": "falhou"}', 500);
        });

        await tester.pumpWidget(MaterialApp(home: tela.value()));
        await tester.pump();
        // Usuário sai da tela enquanto a carga está em andamento
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        liberar.complete();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }

  test('aviso de alteração não quebra com a aba já fechada', () {
    // Simula salvar um dado depois que as abas foram descartadas (logout)
    expect(() => ApiService.alteracoes.value++, returnsNormally);
    expect(Animal.fromMap({'id': 1, 'nome': 'x'}).nome, 'x');
  });
}
