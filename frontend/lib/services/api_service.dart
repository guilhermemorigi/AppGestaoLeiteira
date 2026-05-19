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
}
