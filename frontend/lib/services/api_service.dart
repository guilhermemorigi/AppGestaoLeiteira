import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Erro retornado pelo backend, com a mensagem amigável enviada no corpo
/// da resposta ({"status": ..., "message": ...}).
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Mensagem para exibir ao usuário a partir de qualquer erro de chamada à API.
String describeError(Object error,
    {String fallback = 'Erro ao conectar com o servidor.'}) {
  return error is ApiException ? error.message : fallback;
}

class ApiService {
  /// URL da API. Pode ser definida na execução:
  ///   flutter run --dart-define=API_URL=http://192.168.0.10:8080/api
  /// Sem isso, usa 10.0.2.2 no emulador Android (localhost do PC) e
  /// localhost nas demais plataformas (Web, Windows, iOS Simulator).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static const _timeout = Duration(seconds: 15);
  static const _jsonHeaders = {'Content-Type': 'application/json'};

  // --- INFRAESTRUTURA HTTP ---

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> _send(Future<http.Response> request) async {
    final response = await request.timeout(_timeout);
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body.isEmpty ? null : jsonDecode(body);
    }
    throw ApiException(response.statusCode, _extractMessage(body));
  }

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'];
      }
    } catch (_) {}
    return 'Erro inesperado no servidor.';
  }

  Future<dynamic> _get(String path) => _send(http.get(_uri(path)));

  Future<dynamic> _post(String path, [Object? body]) =>
      _send(http.post(_uri(path),
          headers: _jsonHeaders, body: body == null ? null : jsonEncode(body)));

  Future<dynamic> _put(String path, Object body) => _send(
      http.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<dynamic> _patch(String path) => _send(http.patch(_uri(path)));

  Future<void> _delete(String path) => _send(http.delete(_uri(path)));

  Future<List<T>> _getList<T>(
      String path, T Function(Map<String, dynamic>) fromMap) async {
    final List<dynamic> body = await _get(path);
    return body.map((item) => fromMap(item as Map<String, dynamic>)).toList();
  }

  // --- USUÁRIOS / AUTENTICAÇÃO ---

  /// Lança [ApiException] com a mensagem do servidor em caso de falha
  /// (credenciais inválidas, usuário inativo, etc.).
  Future<User> login(String username, String password) async {
    return User.fromMap(await _post(
        '/users/login', {'username': username, 'password': password}));
  }

  /// Cadastro público (tela "Cadastre-se"): o servidor define o perfil.
  Future<User> signup(User user) async =>
      User.fromMap(await _post('/users/signup', user.toJson()));

  /// Criação pela tela de gerenciamento de usuários (com perfil escolhido).
  Future<User> createUser(User user) async =>
      User.fromMap(await _post('/users', user.toJson()));

  Future<List<User>> getAllUsers() => _getList('/users', User.fromMap);

  Future<User> updateUser(int id, User user) async =>
      User.fromMap(await _put('/users/$id', user.toJson()));

  Future<void> deleteUser(int id) => _delete('/users/$id');

  // --- ANIMAIS ---

  Future<List<Animal>> getAllAnimals() => _getList('/animals', Animal.fromMap);

  Future<Animal> getAnimal(int id) async =>
      Animal.fromMap(await _get('/animals/$id'));

  Future<Animal> createAnimal(Animal animal) async =>
      Animal.fromMap(await _post('/animals', animal.toJson()));

  Future<Animal> updateAnimal(int id, Animal animal) async =>
      Animal.fromMap(await _put('/animals/$id', animal.toJson()));

  Future<void> deleteAnimal(int id) => _delete('/animals/$id');

  // --- PRODUÇÃO ---

  Future<List<Production>> getAllProduction() =>
      _getList('/production', Production.fromMap);

  Future<List<Production>> getProductionByAnimal(int animalId) =>
      _getList('/production/animal/$animalId', Production.fromMap);

  Future<Production> createProduction(Production production) async =>
      Production.fromMap(await _post('/production', production.toJson()));

  Future<Production> updateProduction(int id, Production production) async =>
      Production.fromMap(await _put('/production/$id', production.toJson()));

  Future<void> deleteProduction(int id) => _delete('/production/$id');

  // --- GASTOS (EXPENSES) ---

  Future<List<Expense>> getAllExpenses() =>
      _getList('/expenses', Expense.fromMap);

  Future<Expense> createExpense(Expense expense) async =>
      Expense.fromMap(await _post('/expenses', expense.toJson()));

  Future<Expense> updateExpense(int id, Expense expense) async =>
      Expense.fromMap(await _put('/expenses/$id', expense.toJson()));

  Future<void> deleteExpense(int id) => _delete('/expenses/$id');

  // --- LEMBRETES ---

  Future<List<Reminder>> getAllReminders() =>
      _getList('/reminders', Reminder.fromMap);

  Future<Reminder> createReminder(Reminder reminder) async =>
      Reminder.fromMap(await _post('/reminders', reminder.toJson()));

  Future<Reminder> updateReminder(int id, Reminder reminder) async =>
      Reminder.fromMap(await _put('/reminders/$id', reminder.toJson()));

  Future<void> updateReminderStatus(int id, bool concluido) =>
      _patch('/reminders/$id/status?concluido=$concluido');

  Future<void> deleteReminder(int id) => _delete('/reminders/$id');

  // --- ESTOQUE ---

  Future<List<StockItem>> getAllStock() =>
      _getList('/stock', StockItem.fromMap);

  Future<StockItem> createStock(StockItem item) async =>
      StockItem.fromMap(await _post('/stock', item.toJson()));

  Future<StockItem> updateStock(int id, StockItem item) async =>
      StockItem.fromMap(await _put('/stock/$id', item.toJson()));

  Future<StockItem> adjustStock(int id, double delta) async =>
      StockItem.fromMap(await _patch('/stock/$id/quantidade?delta=$delta'));

  Future<void> deleteStock(int id) => _delete('/stock/$id');

  // --- SAÚDE E TRATAMENTOS ---

  Future<List<HealthRecord>> getAllHealth() =>
      _getList('/health', HealthRecord.fromMap);

  Future<List<HealthRecord>> getHealthByAnimal(int animalId) =>
      _getList('/health/animal/$animalId', HealthRecord.fromMap);

  Future<HealthRecord> createHealth(HealthRecord record) async =>
      HealthRecord.fromMap(await _post('/health', record.toJson()));

  Future<HealthRecord> updateHealth(int id, HealthRecord record) async =>
      HealthRecord.fromMap(await _put('/health/$id', record.toJson()));

  Future<void> deleteHealth(int id) => _delete('/health/$id');

  // --- VACINAS ---

  Future<List<Vaccine>> getAllVaccines() =>
      _getList('/vaccines', Vaccine.fromMap);

  Future<List<Vaccine>> getVaccinesByAnimal(int animalId) =>
      _getList('/vaccines/animal/$animalId', Vaccine.fromMap);

  Future<Vaccine> createVaccine(Vaccine vaccine) async =>
      Vaccine.fromMap(await _post('/vaccines', vaccine.toJson()));

  Future<Vaccine> updateVaccine(int id, Vaccine vaccine) async =>
      Vaccine.fromMap(await _put('/vaccines/$id', vaccine.toJson()));

  Future<void> deleteVaccine(int id) => _delete('/vaccines/$id');

  // --- REPRODUÇÃO ---

  Future<List<Reproduction>> getAllReproduction() =>
      _getList('/reproduction', Reproduction.fromMap);

  Future<List<Reproduction>> getReproductionByAnimal(int animalId) =>
      _getList('/reproduction/animal/$animalId', Reproduction.fromMap);

  Future<Reproduction> createReproduction(Reproduction r) async =>
      Reproduction.fromMap(await _post('/reproduction', r.toJson()));

  Future<Reproduction> updateReproduction(int id, Reproduction r) async =>
      Reproduction.fromMap(await _put('/reproduction/$id', r.toJson()));

  Future<void> deleteReproduction(int id) => _delete('/reproduction/$id');
}
