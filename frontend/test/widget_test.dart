import 'package:flutter_test/flutter_test.dart';

import 'package:app_gestao_leiteira/models/models.dart';
import 'package:app_gestao_leiteira/services/api_service.dart';

void main() {
  group('Serialização no formato da API', () {
    test('Production envia referência ao animal e data com milissegundos', () {
      final json = Production(
        animalId: 7,
        animalNome: 'Mimosa',
        data: DateTime(2026, 10, 20, 6, 30),
        quantidade: 18.5,
      ).toJson();

      expect(json['animal'], {'id': 7});
      expect(json['data'], '2026-10-20T06:30:00.000');
      expect(json['quantidade'], 18.5);
    });

    test('Animal envia data de nascimento no formato do backend', () {
      final json = Animal(
        nome: 'Estrela',
        idade: 2,
        raca: 'Jersey',
        dataNascimento: DateTime(2024, 3, 10),
      ).toJson();

      expect(json['dataNascimento'], '2024-03-10T00:00:00.000');
      expect(json.containsKey('id'), isFalse);
    });

    test('User nunca lê senha da resposta', () {
      final user =
          User.fromMap({'id': 1, 'username': 'admin', 'role': 'ADMIN'});
      expect(user.password, isEmpty);
      expect(user.ativo, isTrue);
    });
  });

  group('Leitura das respostas da API', () {
    test('HealthRecord lê o animal aninhado e datas sem milissegundos', () {
      final r = HealthRecord.fromMap({
        'id': 3,
        'animal': {'id': 7, 'nome': 'Mimosa'},
        'tipo': 'Tratamento',
        'descricao': 'Mastite',
        'data': '2026-10-22T00:00:00',
        'custo': 150,
        'status': 'Em andamento',
      });

      expect(r.animalId, 7);
      expect(r.animalNome, 'Mimosa');
      expect(r.data, DateTime(2026, 10, 22));
      expect(r.custo, 150.0);
    });

    test('Expense e Reminder identificam lançamentos automáticos', () {
      final e = Expense.fromMap({
        'id': 1,
        'descricao': 'Tratamento: Mastite (Mimosa)',
        'valor': 150,
        'data': '2026-10-22T00:00:00',
        'categoria': 'Veterinário',
        'origem': 'SAUDE',
      });
      final r = Reminder.fromMap({
        'id': 2,
        'titulo': 'Vacina: Aftosa - Estrela',
        'descricao': null,
        'data': '2027-04-01T00:00:00',
        'concluido': false,
        'origem': 'VACINA',
      });

      expect(e.automatica, isTrue);
      expect(r.origem, 'VACINA');
      expect(r.descricao, isEmpty);
    });
  });

  test('describeError usa a mensagem do servidor quando existe', () {
    expect(describeError(ApiException(409, 'Animal possui histórico.')),
        'Animal possui histórico.');
    expect(describeError(Exception('timeout'), fallback: 'Sem conexão'),
        'Sem conexão');
  });
}
