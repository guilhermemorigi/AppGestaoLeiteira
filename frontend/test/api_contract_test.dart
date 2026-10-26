// Teste de integração do ApiService contra um backend real.
// Só roda quando a URL é informada (não use o banco de produção):
//   flutter test test/api_contract_test.dart --dart-define=API_URL=http://localhost:8080/api
import 'package:flutter_test/flutter_test.dart';

import 'package:app_gestao_leiteira/models/models.dart';
import 'package:app_gestao_leiteira/services/api_service.dart';

const _apiUrl = String.fromEnvironment('API_URL');

void main() {
  final api = ApiService();
  final sufixo = DateTime.now().millisecondsSinceEpoch;

  test('fluxo completo do app contra o backend', () async {
    final animal = await api.createAnimal(Animal(
        nome: 'Contrato $sufixo',
        idade: 3,
        raca: 'Girolando',
        dataNascimento: DateTime(2023, 1, 15, 10, 20, 30, 456, 789)));
    expect(animal.id, isNotNull);
    expect(animal.dataNascimento, DateTime(2023, 1, 15, 10, 20, 30, 456));

    // Produção: cria, edita e lê com o nome do animal
    final p = await api.createProduction(Production(
        animalId: animal.id!,
        animalNome: '',
        data: DateTime(2026, 10, 1),
        quantidade: 12.5));
    expect(p.animalNome, animal.nome);
    final p2 = await api.updateProduction(
        p.id!,
        Production(
            animalId: animal.id!,
            animalNome: '',
            data: p.data,
            quantidade: 14));
    expect(p2.quantidade, 14);

    // Saúde com custo gera despesa automática, que não pode ser excluída
    final h = await api.createHealth(HealthRecord(
        animalId: animal.id!,
        animalNome: '',
        tipo: 'Exame',
        descricao: 'Contrato $sufixo',
        data: DateTime(2026, 10, 2),
        custo: 99.9));
    final auto = (await api.getAllExpenses())
        .where((e) => e.automatica && e.descricao.contains('Contrato $sufixo'))
        .toList();
    expect(auto, hasLength(1));
    await expectLater(
        api.deleteExpense(auto.first.id!),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 409)));

    // Vacina com próxima dose gera lembrete; editar a vacina move o lembrete
    final v = await api.createVaccine(Vaccine(
        animalId: animal.id!,
        animalNome: '',
        nome: 'Aftosa',
        dataAplicacao: DateTime(2026, 10, 3),
        proximaDose: DateTime(2027, 4, 3)));
    await api.updateVaccine(
        v.id!,
        Vaccine(
            animalId: animal.id!,
            animalNome: '',
            nome: 'Aftosa',
            dataAplicacao: v.dataAplicacao,
            proximaDose: DateTime(2027, 5, 3)));
    final lembretes = (await api.getAllReminders())
        .where((r) => r.origem == 'VACINA' && r.titulo.contains(animal.nome));
    expect(lembretes.single.data, DateTime(2027, 5, 3));
    await api.updateReminderStatus(lembretes.single.id!, true);

    // Parto coloca o animal em lactação
    final rep = await api.createReproduction(Reproduction(
        animalId: animal.id!,
        animalNome: '',
        tipo: 'Parto',
        data: DateTime(2026, 10, 4),
        status: 'Parida'));
    expect((await api.getAnimal(animal.id!)).status, 'Lactação');

    // Animal com histórico não pode ser excluído
    await expectLater(
        api.deleteAnimal(animal.id!),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Vendido'))));

    // Limpeza: remove o histórico e então o animal
    await api.deleteReproduction(rep.id!);
    await api.deleteVaccine(v.id!);
    await api.deleteHealth(h.id!);
    await api.deleteProduction(p.id!);
    await api.deleteAnimal(animal.id!);
    expect(
        (await api.getAllExpenses())
            .where((e) => e.descricao.contains('Contrato $sufixo')),
        isEmpty);
  }, skip: _apiUrl.isEmpty ? 'Defina --dart-define=API_URL para rodar' : null);
}
