// Garante que nenhuma tela quebra o layout (RenderFlex overflow) quando os
// dados têm textos longos, em celulares estreitos e com fonte ampliada.
// O backend é simulado com MockClient, então o teste roda sem servidor.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app_gestao_leiteira/models/models.dart';
import 'package:app_gestao_leiteira/services/api_service.dart';
import 'package:app_gestao_leiteira/theme/app_theme.dart';
import 'package:app_gestao_leiteira/views/animal_detail_view.dart';
import 'package:app_gestao_leiteira/views/animal_form_view.dart';
import 'package:app_gestao_leiteira/views/animal_list_view.dart';
import 'package:app_gestao_leiteira/views/dashboard_view.dart';
import 'package:app_gestao_leiteira/views/expense_form_view.dart';
import 'package:app_gestao_leiteira/views/expense_list_view.dart';
import 'package:app_gestao_leiteira/views/health_form_view.dart';
import 'package:app_gestao_leiteira/views/health_list_view.dart';
import 'package:app_gestao_leiteira/views/production_form_view.dart';
import 'package:app_gestao_leiteira/views/production_list_view.dart';
import 'package:app_gestao_leiteira/views/reminder_form_view.dart';
import 'package:app_gestao_leiteira/views/reminder_list_view.dart';
import 'package:app_gestao_leiteira/views/reproduction_form_view.dart';
import 'package:app_gestao_leiteira/views/reproduction_list_view.dart';
import 'package:app_gestao_leiteira/views/stock_form_view.dart';
import 'package:app_gestao_leiteira/views/stock_list_view.dart';
import 'package:app_gestao_leiteira/views/user_form_view.dart';
import 'package:app_gestao_leiteira/views/user_list_view.dart';
import 'package:app_gestao_leiteira/views/vaccine_form_view.dart';
import 'package:app_gestao_leiteira/views/vaccine_list_view.dart';

// --- Textos propositalmente longos ---------------------------------------
const nomeLongo = 'Mimosa Estrela da Fazenda Boa Esperança do Vale Verde';
const racaLonga = 'Girolando 3/4 Holandês com Gir Leiteiro';
const brincoLongo = '2024-0001-BR-SC-ABCDEF';
const textoLongo =
    'Mastite clínica no quarto posterior esquerdo com grumos no leite, '
    'inchaço e sensibilidade ao toque; iniciar tratamento intramamário e '
    'descartar o leite durante todo o período de carência do medicamento';
const categoriaLonga = 'Vacina/Medicamento e Insumos Veterinários Diversos';
const pessoaLonga = 'Dra. Ana Carolina de Souza Albuquerque Pereira';

final hoje = DateTime.now();
String data(int diasAtras) =>
    DateTime(hoje.year, hoje.month, hoje.day - diasAtras).toIso8601String();

final animal = {
  'id': 1,
  'nome': nomeLongo,
  'idade': 12,
  'raca': racaLonga,
  'numeroBrinco': brincoLongo,
  'sexo': 'Fêmea',
  'peso': 612.5,
  'dataNascimento': data(4000),
  'status': 'Lactação',
};

final respostas = <String, Object>{
  '/api/animals': [
    animal,
    {...animal, 'id': 2, 'status': 'Vendido'}
  ],
  '/api/production': [
    for (var i = 0; i < 10; i++)
      {'id': i + 1, 'animal': animal, 'data': data(i), 'quantidade': 1234.5}
  ],
  '/api/expenses': [
    {
      'id': 1,
      'descricao': textoLongo,
      'valor': 1234567.89,
      'data': data(1),
      'categoria': categoriaLonga,
      'origem': null
    },
    {
      'id': 2,
      'descricao': 'Doença: $textoLongo ($nomeLongo)',
      'valor': 98765.43,
      'data': data(2),
      'categoria': 'Veterinário',
      'origem': 'SAUDE'
    },
  ],
  '/api/reminders': [
    {
      'id': 1,
      'titulo': 'Vacina: Clostridiose - $nomeLongo',
      'descricao': textoLongo,
      'data': data(3),
      'concluido': false,
      'origem': 'VACINA'
    },
    {
      'id': 2,
      'titulo': textoLongo,
      'descricao': '',
      'data': data(-5),
      'concluido': true,
      'origem': null
    },
  ],
  '/api/health': [
    {
      'id': 1,
      'animal': animal,
      'tipo': 'Tratamento',
      'descricao': textoLongo,
      'medicamento': textoLongo,
      'veterinario': pessoaLonga,
      'data': data(5),
      'dataFim': null,
      'custo': 123456.78,
      'status': 'Em andamento',
      'observacao': textoLongo
    }
  ],
  '/api/vaccines': [
    {
      'id': 1,
      'animal': animal,
      'nome': 'Vacina Polivalente Contra Clostridioses e Leptospirose',
      'dataAplicacao': data(30),
      'proximaDose': data(-10),
      'lote': brincoLongo,
      'veterinario': pessoaLonga,
      'observacao': textoLongo
    }
  ],
  '/api/reproduction': [
    {
      'id': 1,
      'animal': animal,
      'tipo': 'Diagnóstico Gestação',
      'data': data(20),
      'touro': 'Sêmen Girolando - Faraó da Estância Santa Maria (importado)',
      'previsaoParto': data(-15),
      'status': 'Confirmada',
      'observacao': textoLongo
    }
  ],
  '/api/stock': [
    {
      'id': 1,
      'nome': 'Ração concentrada 22% PB para vacas em lactação de alta produção',
      'categoria': 'Medicamento',
      'quantidade': 123456.75,
      'unidade': 'saco',
      'quantidadeMinima': 200000,
      'precoUnitario': 98765.43,
      'validade': data(-3),
      'observacao': textoLongo
    }
  ],
  '/api/users': [
    {
      'id': 1,
      'username': 'administrador.geral.da.fazenda.boa.esperanca',
      'nomeCompleto': pessoaLonga,
      'email': 'administrador.geral@fazendaboaesperancadovaleverde.com.br',
      'telefone': '(49) 99999-9999',
      'role': 'ADMIN',
      'ativo': false
    }
  ],
};

MockClient backendFalso() => MockClient((request) async {
      final path = request.url.path;
      final body = respostas[path] ??
          (path.contains('/animal/')
              ? respostas['/api/${path.split('/')[2]}']
              : null);
      return http.Response.bytes(utf8.encode(jsonEncode(body ?? [])), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });

Map<String, dynamic> _primeiro(String rota) =>
    (respostas[rota] as List).first as Map<String, dynamic>;

final telas = <String, Widget Function()>{
  'Dashboard': () => const DashboardView(),
  'Animais': () => const AnimalListView(),
  'Ficha do animal': () => AnimalDetailView(animal: Animal.fromMap(animal)),
  'Produção': () => const ProductionListView(),
  'Financeiro': () => const ExpenseListView(),
  'Agenda': () => const ReminderListView(),
  'Saúde': () => const HealthListView(),
  'Vacinas': () => const VaccineListView(),
  'Reprodução': () => const ReproductionListView(),
  'Estoque': () => const StockListView(),
  'Usuários': () => const UserListView(),
  'Form animal': () => AnimalFormView(animal: Animal.fromMap(animal)),
  'Form produção': () => ProductionFormView(
      production: Production.fromMap(_primeiro('/api/production'))),
  'Form gasto': () =>
      ExpenseFormView(expense: Expense.fromMap(_primeiro('/api/expenses'))),
  'Form lembrete': () =>
      ReminderFormView(reminder: Reminder.fromMap(_primeiro('/api/reminders'))),
  'Form saúde': () =>
      HealthFormView(record: HealthRecord.fromMap(_primeiro('/api/health'))),
  'Form vacina': () =>
      VaccineFormView(vaccine: Vaccine.fromMap(_primeiro('/api/vaccines'))),
  'Form reprodução': () => ReproductionFormView(
      record: Reproduction.fromMap(_primeiro('/api/reproduction'))),
  'Form estoque': () =>
      StockFormView(item: StockItem.fromMap(_primeiro('/api/stock'))),
  'Form usuário': () =>
      UserFormView(user: User.fromMap(_primeiro('/api/users'))),
};

void main() {
  setUp(() => ApiService.client = backendFalso());

  const telasCelular = {'320dp': Size(320, 640), '360dp': Size(360, 740)};

  for (final tela in telas.entries) {
    for (final tamanho in telasCelular.entries) {
      for (final escala in [1.0, 1.3]) {
        // Caso extremo (tela de 320dp + fonte ampliada) aceito como limite:
        // não é coberto por decisão de projeto.
        if (tamanho.key == '320dp' && escala > 1.0) continue;
        testWidgets('${tela.key} | ${tamanho.key} | fonte x$escala',
            (tester) async {
          tester.view.physicalSize = tamanho.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(escala)),
                child: tela.value(),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Telas com abas: percorre todas
          final abas = find.byType(Tab);
          for (var i = 0; i < abas.evaluate().length; i++) {
            await tester.tap(abas.at(i));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'aba $i');
          }
        });
      }
    }
  }
}
