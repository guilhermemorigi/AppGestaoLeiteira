import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/models.dart';

class ApiService {
  // Use 10.0.2.2 para o emulador Android (aponta para o localhost do PC)
  // Use localhost para iOS ou Web
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Backend espera exatamente 3 casas decimais: "yyyy-MM-dd'T'HH:mm:ss.SSS"
  static final _dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
  static String _fmt(DateTime date) => _dateFormat.format(date);

  // --- MÉTODOS DE USUÁRIO (LOGIN/SIGNUP) ---

  Future<User?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(response.body));
    }
    return null; // Credenciais inválidas
  }

  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toMap()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao criar usuário (Username já pode existir)');
  }

  // --- MÉTODOS DE ANIMAIS ---

  Future<List<Animal>> getAllAnimals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/animals'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Animal.fromMap(item)).toList();
      } else {
        throw Exception('Falha ao carregar animais');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Animal> createAnimal(Animal animal) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/animals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(animal.toMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Animal.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao criar animal');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Animal> updateAnimal(int id, Animal animal) async {
    final response = await http.put(
      Uri.parse('$baseUrl/animals/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(animal.toMap()),
    );
    if (response.statusCode == 200) {
      return Animal.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao atualizar animal');
  }

  Future<void> deleteAnimal(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/animals/$id'));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Falha ao deletar animal');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- MÉTODOS DE GASTOS (EXPENSES) ---

  Future<List<Expense>> getAllExpenses() async {
    final response = await http.get(Uri.parse('$baseUrl/expenses'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Expense.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar gastos');
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'descricao': expense.descricao,
        'valor': expense.valor,
        'data': _fmt(expense.data),
        'categoria': expense.categoria,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Expense.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao criar gasto');
  }

  Future<void> deleteExpense(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/expenses/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao deletar gasto');
    }
  }

  Future<double> getTotalExpenses() async {
    final expenses = await getAllExpenses();
    return expenses.fold<double>(0.0, (sum, item) => sum + item.valor);
  }

  // --- MÉTODOS DE PRODUÇÃO ---

  Future<List<Production>> getAllProduction() async {
    final response = await http.get(Uri.parse('$baseUrl/production'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map((item) =>
              Production.fromMap(item, animalNome: item['animal']?['nome']))
          .toList();
    }
    throw Exception('Falha ao carregar produção');
  }

  Future<List<Production>> getProductionByAnimal(int animalId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/production/animal/$animalId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map((item) =>
              Production.fromMap(item, animalNome: item['animal']?['nome']))
          .toList();
    }
    throw Exception('Falha ao carregar produção do animal');
  }

  Future<Production> createProduction(Production production) async {
    final response = await http.post(
      Uri.parse('$baseUrl/production'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'animal': {'id': production.animalId},
        'data': _fmt(production.data),
        'quantidade': production.quantidade,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return Production.fromMap(body, animalNome: body['animal']?['nome']);
    }
    throw Exception('Falha ao registrar produção');
  }

  Future<void> deleteProduction(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/production/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao deletar produção');
    }
  }

  // --- MÉTODOS DE LEMBRETES ---

  Future<List<Reminder>> getAllReminders() async {
    final response = await http.get(Uri.parse('$baseUrl/reminders'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Reminder.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar lembretes');
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': reminder.titulo,
        'descricao': reminder.descricao,
        'data': _fmt(reminder.data),
        'concluido': reminder.concluido,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reminder.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao criar lembrete');
  }

  Future<void> updateReminderStatus(int id, bool concluido) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/reminders/$id/status?concluido=$concluido'),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar status do lembrete');
    }
  }

  Future<void> deleteReminder(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/reminders/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao deletar lembrete');
    }
  }

  // --- GERENCIAMENTO DE USUÁRIOS ---

  Future<List<User>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => User.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar usuários');
  }

  Future<User> updateUser(int id, User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toMap()),
    );
    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao atualizar usuário');
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao excluir usuário');
    }
  }

  // --- ESTOQUE ---

  Future<List<StockItem>> getAllStock() async {
    final response = await http.get(Uri.parse('$baseUrl/stock'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => StockItem.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar estoque');
  }

  Future<StockItem> createStock(StockItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': item.nome,
        'categoria': item.categoria,
        'quantidade': item.quantidade,
        'unidade': item.unidade,
        'quantidadeMinima': item.quantidadeMinima,
        'precoUnitario': item.precoUnitario,
        'validade': item.validade != null ? _fmt(item.validade!) : null,
        'observacao': item.observacao,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return StockItem.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao criar item de estoque');
  }

  Future<StockItem> updateStock(int id, StockItem item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/stock/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': item.nome,
        'categoria': item.categoria,
        'quantidade': item.quantidade,
        'unidade': item.unidade,
        'quantidadeMinima': item.quantidadeMinima,
        'precoUnitario': item.precoUnitario,
        'validade': item.validade != null ? _fmt(item.validade!) : null,
        'observacao': item.observacao,
      }),
    );
    if (response.statusCode == 200) {
      return StockItem.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao atualizar item de estoque');
  }

  Future<StockItem> adjustStock(int id, double delta) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/stock/$id/quantidade?delta=$delta'),
    );
    if (response.statusCode == 200) {
      return StockItem.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao ajustar quantidade');
  }

  Future<void> deleteStock(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/stock/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao excluir item de estoque');
    }
  }

  // --- SAÚDE E TRATAMENTOS ---

  Future<List<HealthRecord>> getAllHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => HealthRecord.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar registros de saúde');
  }

  Future<List<HealthRecord>> getHealthByAnimal(int animalId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/health/animal/$animalId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => HealthRecord.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar saúde do animal');
  }

  Future<HealthRecord> createHealth(HealthRecord record) async {
    final response = await http.post(
      Uri.parse('$baseUrl/health'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'animal': {'id': record.animalId},
        'tipo': record.tipo,
        'descricao': record.descricao,
        'medicamento': record.medicamento,
        'veterinario': record.veterinario,
        'data': _fmt(record.data),
        'dataFim': record.dataFim != null ? _fmt(record.dataFim!) : null,
        'custo': record.custo,
        'status': record.status,
        'observacao': record.observacao,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return HealthRecord.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao registrar saúde');
  }

  Future<void> deleteHealth(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/health/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao excluir registro de saúde');
    }
  }

  // --- VACINAS ---

  Future<List<Vaccine>> getAllVaccines() async {
    final response = await http.get(Uri.parse('$baseUrl/vaccines'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Vaccine.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar vacinas');
  }

  Future<List<Vaccine>> getVaccinesByAnimal(int animalId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/vaccines/animal/$animalId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Vaccine.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar vacinas do animal');
  }

  Future<Vaccine> createVaccine(Vaccine vaccine) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vaccines'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'animal': {'id': vaccine.animalId},
        'nome': vaccine.nome,
        'dataAplicacao': _fmt(vaccine.dataAplicacao),
        'proximaDose':
            vaccine.proximaDose != null ? _fmt(vaccine.proximaDose!) : null,
        'lote': vaccine.lote,
        'veterinario': vaccine.veterinario,
        'observacao': vaccine.observacao,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Vaccine.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao registrar vacina');
  }

  Future<void> deleteVaccine(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/vaccines/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao excluir vacina');
    }
  }

  // --- REPRODUÇÃO ---

  Future<List<Reproduction>> getAllReproduction() async {
    final response = await http.get(Uri.parse('$baseUrl/reproduction'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Reproduction.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar reprodução');
  }

  Future<List<Reproduction>> getReproductionByAnimal(int animalId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/reproduction/animal/$animalId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Reproduction.fromMap(item)).toList();
    }
    throw Exception('Falha ao carregar reprodução do animal');
  }

  Future<Reproduction> createReproduction(Reproduction r) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reproduction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'animal': {'id': r.animalId},
        'tipo': r.tipo,
        'data': _fmt(r.data),
        'touro': r.touro,
        'previsaoParto':
            r.previsaoParto != null ? _fmt(r.previsaoParto!) : null,
        'status': r.status,
        'observacao': r.observacao,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reproduction.fromMap(jsonDecode(response.body));
    }
    throw Exception('Falha ao registrar reprodução');
  }

  Future<void> deleteReproduction(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/reproduction/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao excluir registro de reprodução');
    }
  }
}
