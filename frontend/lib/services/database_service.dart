import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('leiteira.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          descricao TEXT NOT NULL,
          valor REAL NOT NULL,
          data TEXT NOT NULL,
          categoria TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT NOT NULL,
          descricao TEXT NOT NULL,
          data TEXT NOT NULL,
          concluido INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE animals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        idade INTEGER NOT NULL,
        raca TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE production (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        quantidade REAL NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        data TEXT NOT NULL,
        concluido INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // --- MÉTODOS DE USUÁRIO ---
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> login(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  // --- MÉTODOS DE GASTOS (EXPENSES) ---
  Future<int> createExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'data DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<double> getTotalExpenses() async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT SUM(valor) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // --- MÉTODOS DE LEMBRETES (REMINDERS) ---
  Future<int> createReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await instance.database;
    final result = await db.query('reminders', orderBy: 'data ASC');
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<void> updateReminderStatus(int id, bool concluido) async {
    final db = await instance.database;
    await db.update(
      'reminders',
      {'concluido': concluido ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS DE ANIMAIS ---
  Future<int> createAnimal(Animal animal) async {
    final db = await instance.database;
    return await db.insert('animals', animal.toMap());
  }

  Future<List<Animal>> getAllAnimals() async {
    final db = await instance.database;
    final result = await db.query('animals');
    return result.map((json) => Animal.fromMap(json)).toList();
  }

  // --- MÉTODOS DE PRODUÇÃO ---
  Future<int> createProduction(Production production) async {
    final db = await instance.database;
    return await db.insert('production', production.toMap());
  }

  Future<List<Production>> getProductionByAnimal(int animalId) async {
    final db = await instance.database;
    final result = await db.query(
      'production',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return result.map((json) => Production.fromMap(json)).toList();
  }

  Future<List<Production>> getAllProduction() async {
    final db = await instance.database;
    const query = '''
      SELECT p.*, a.nome as animal_nome
      FROM production p
      JOIN animals a ON p.animal_id = a.id
      ORDER BY p.data DESC
    ''';
    final result = await db.rawQuery(query);
    return result.map((json) => Production.fromMap(json)).toList();
  }

  Future<void> syncAnimals(List<Animal> animals) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var a in animals) {
      if (a.id != null) {
        batch.insert('animals', a.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> syncProduction(List<Production> productions) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var p in productions) {
      if (p.id != null) {
        batch.insert('production', p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  // --- RELATÓRIOS ---
  Future<double> getTotalProduction(
      {String? startDate, String? endDate}) async {
    final db = await instance.database;
    String whereClause = '';
    List<String> args = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date(data) BETWEEN ? AND ?';
      args = [startDate, endDate];
    }

    final result = await db.rawQuery(
        'SELECT SUM(quantidade) as total FROM production $whereClause', args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getDailyTotals(
      {String? startDate, String? endDate}) async {
    final db = await instance.database;
    String whereClause = '';
    List<String> args = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date(data) BETWEEN ? AND ?';
      args = [startDate, endDate];
    }

    final result = await db.rawQuery('''
      SELECT substr(data, 1, 10) as dia, SUM(quantidade) as total 
      FROM production 
      $whereClause
      GROUP BY dia 
      ORDER BY dia ASC
    ''', args);

    Map<String, double> totals = {};
    for (var row in result) {
      totals[row['dia'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  Future<Map<String, dynamic>?> getTopProducingAnimal(
      {String? startDate, String? endDate}) async {
    final db = await instance.database;
    String whereClause = '';
    List<String> args = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date(p.data) BETWEEN ? AND ?';
      args = [startDate, endDate];
    }

    final result = await db.rawQuery('''
      SELECT a.nome, SUM(p.quantidade) as total 
      FROM production p 
      JOIN animals a ON p.animal_id = a.id 
      $whereClause
      GROUP BY a.id 
      ORDER BY total DESC 
      LIMIT 1
    ''', args);

    return result.isNotEmpty ? result.first : null;
  }

  // --- MÉTODOS DE EXCLUSÃO ---
  Future<int> deleteAnimal(int id) async {
    final db = await instance.database;
    // O delete cascade deve cuidar da produção, mas vamos garantir
    return await db.delete('animals', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduction(int id) async {
    final db = await instance.database;
    return await db.delete('production', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // O novo método que você pediu
  Future<List<Map<String, dynamic>>> getProductionDetailsByDate(
      String date) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT a.nome, p.quantidade 
      FROM production p 
      JOIN animals a ON p.animal_id = a.id 
      WHERE p.data LIKE ?
    ''', ['$date%']);
  }
}
