class User {
  final int? id;
  final String username;
  final String password;

  User({
    this.id,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }
}

class Animal {
  final int? id;
  final String nome;
  final int idade;
  final String raca;

  Animal({
    this.id,
    required this.nome,
    required this.idade,
    required this.raca,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'idade': idade,
      'raca': raca,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      nome: map['nome'],
      idade: map['idade'],
      raca: map['raca'],
    );
  }
}

class Production {
  final int? id;
  final int animalId;
  final String animalNome;
  final DateTime data;
  final double quantidade;

  Production({
    this.id,
    required this.animalId,
    required this.animalNome,
    required this.data,
    required this.quantidade,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'data': data.toIso8601String(),
      'quantidade': quantidade,
    };
  }

  factory Production.fromMap(Map<String, dynamic> map, {String? animalNome}) {
    return Production(
      id: map['id'],
      animalId: map['animal_id'] ??
          (map['animal'] as Map<String, dynamic>?)?['id'] ??
          0,
      animalNome: animalNome ?? map['animal_nome'] ?? 'Desconhecido',
      data: DateTime.parse(map['data']),
      quantidade: (map['quantidade'] as num).toDouble(),
    );
  }
}

class Expense {
  final int? id;
  final String descricao;
  final double valor;
  final DateTime data;
  final String categoria; // Ração, Vacina, Manutenção, etc.

  Expense({
    this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.categoria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
      'categoria': categoria,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      descricao: map['descricao'],
      valor: (map['valor'] as num).toDouble(),
      data: DateTime.parse(map['data']),
      categoria: map['categoria'],
    );
  }
}

class Reminder {
  final int? id;
  final String titulo;
  final String descricao;
  final DateTime data;
  final bool concluido;

  Reminder({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.data,
    this.concluido = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'concluido': concluido ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      titulo: map['titulo'],
      descricao: map['descricao'],
      data: DateTime.parse(map['data']),
      concluido: map['concluido'] == 1 || map['concluido'] == true,
    );
  }
}
