class User {
  final int? id;
  final String username;
  final String password;
  final String? nomeCompleto;
  final String? email;
  final String? telefone;
  final String role; // ADMIN, OPERADOR
  final bool ativo;

  User({
    this.id,
    required this.username,
    required this.password,
    this.nomeCompleto,
    this.email,
    this.telefone,
    this.role = 'OPERADOR',
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'nomeCompleto': nomeCompleto,
      'email': email,
      'telefone': telefone,
      'role': role,
      'ativo': ativo,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      nomeCompleto: map['nomeCompleto'],
      email: map['email'],
      telefone: map['telefone'],
      role: map['role'] ?? 'OPERADOR',
      ativo: map['ativo'] == null ? true : (map['ativo'] == true || map['ativo'] == 1),
    );
  }
}

class Animal {
  final int? id;
  final String nome;
  final int idade;
  final String raca;
  final String? numeroBrinco;
  final String? sexo; // Fêmea, Macho
  final double? peso;
  final DateTime? dataNascimento;
  final String status; // Ativo, Vendido, Morto, Seco, Lactação

  Animal({
    this.id,
    required this.nome,
    required this.idade,
    required this.raca,
    this.numeroBrinco,
    this.sexo,
    this.peso,
    this.dataNascimento,
    this.status = 'Ativo',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'idade': idade,
      'raca': raca,
      'numeroBrinco': numeroBrinco,
      'sexo': sexo,
      'peso': peso,
      'dataNascimento': dataNascimento?.toIso8601String(),
      'status': status,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      nome: map['nome'] ?? '',
      idade: (map['idade'] as int?) ?? 0,
      raca: (map['raca'] as String?) ?? '',
      numeroBrinco: map['numeroBrinco'],
      sexo: map['sexo'],
      peso: (map['peso'] as num?)?.toDouble(),
      dataNascimento: map['dataNascimento'] != null
          ? DateTime.tryParse(map['dataNascimento'])
          : null,
      status: map['status'] ?? 'Ativo',
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

/// Item de estoque (ração, medicamentos, insumos, etc.)
class StockItem {
  final int? id;
  final String nome;
  final String categoria;
  final double quantidade;
  final String unidade;
  final double quantidadeMinima;
  final double precoUnitario;
  final DateTime? validade;
  final String? observacao;

  StockItem({
    this.id,
    required this.nome,
    required this.categoria,
    required this.quantidade,
    required this.unidade,
    this.quantidadeMinima = 0,
    this.precoUnitario = 0,
    this.validade,
    this.observacao,
  });

  bool get estoqueBaixo =>
      quantidadeMinima > 0 && quantidade <= quantidadeMinima;

  double get valorTotal => quantidade * precoUnitario;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'quantidade': quantidade,
      'unidade': unidade,
      'quantidadeMinima': quantidadeMinima,
      'precoUnitario': precoUnitario,
      'validade': validade?.toIso8601String(),
      'observacao': observacao,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'],
      nome: map['nome'] ?? '',
      categoria: map['categoria'] ?? 'Outros',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0,
      unidade: map['unidade'] ?? 'un',
      quantidadeMinima: (map['quantidadeMinima'] as num?)?.toDouble() ?? 0,
      precoUnitario: (map['precoUnitario'] as num?)?.toDouble() ?? 0,
      validade: map['validade'] != null
          ? DateTime.tryParse(map['validade'])
          : null,
      observacao: map['observacao'],
    );
  }
}

/// Registro de saúde / tratamento de um animal
class HealthRecord {
  final int? id;
  final int animalId;
  final String animalNome;
  final String tipo; // Doença, Tratamento, Exame, Cirurgia, Vermífugo
  final String descricao;
  final String? medicamento;
  final String? veterinario;
  final DateTime data;
  final DateTime? dataFim;
  final double custo;
  final String status; // Em andamento, Concluído
  final String? observacao;

  HealthRecord({
    this.id,
    required this.animalId,
    required this.animalNome,
    required this.tipo,
    required this.descricao,
    this.medicamento,
    this.veterinario,
    required this.data,
    this.dataFim,
    this.custo = 0,
    this.status = 'Em andamento',
    this.observacao,
  });

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      animalId: (map['animal'] as Map<String, dynamic>?)?['id'] ??
          map['animal_id'] ??
          0,
      animalNome: (map['animal'] as Map<String, dynamic>?)?['nome'] ??
          map['animal_nome'] ??
          'Desconhecido',
      tipo: map['tipo'] ?? 'Tratamento',
      descricao: map['descricao'] ?? '',
      medicamento: map['medicamento'],
      veterinario: map['veterinario'],
      data: DateTime.parse(map['data']),
      dataFim: map['dataFim'] != null ? DateTime.tryParse(map['dataFim']) : null,
      custo: (map['custo'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'Em andamento',
      observacao: map['observacao'],
    );
  }
}

/// Registro de vacinação de um animal
class Vaccine {
  final int? id;
  final int animalId;
  final String animalNome;
  final String nome;
  final DateTime dataAplicacao;
  final DateTime? proximaDose;
  final String? lote;
  final String? veterinario;
  final String? observacao;

  Vaccine({
    this.id,
    required this.animalId,
    required this.animalNome,
    required this.nome,
    required this.dataAplicacao,
    this.proximaDose,
    this.lote,
    this.veterinario,
    this.observacao,
  });

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'],
      animalId: (map['animal'] as Map<String, dynamic>?)?['id'] ??
          map['animal_id'] ??
          0,
      animalNome: (map['animal'] as Map<String, dynamic>?)?['nome'] ??
          map['animal_nome'] ??
          'Desconhecido',
      nome: map['nome'] ?? '',
      dataAplicacao: DateTime.parse(map['dataAplicacao']),
      proximaDose: map['proximaDose'] != null
          ? DateTime.tryParse(map['proximaDose'])
          : null,
      lote: map['lote'],
      veterinario: map['veterinario'],
      observacao: map['observacao'],
    );
  }
}

/// Registro reprodutivo de um animal (cio, cobertura, gestação, parto)
class Reproduction {
  final int? id;
  final int animalId;
  final String animalNome;
  final String tipo; // Cio, Cobertura, Inseminação, Diagnóstico Gestação, Parto
  final DateTime data;
  final String? touro;
  final DateTime? previsaoParto;
  final String status; // Pendente, Confirmada, Prenhe, Vazia, Parida
  final String? observacao;

  Reproduction({
    this.id,
    required this.animalId,
    required this.animalNome,
    required this.tipo,
    required this.data,
    this.touro,
    this.previsaoParto,
    this.status = 'Pendente',
    this.observacao,
  });

  factory Reproduction.fromMap(Map<String, dynamic> map) {
    return Reproduction(
      id: map['id'],
      animalId: (map['animal'] as Map<String, dynamic>?)?['id'] ??
          map['animal_id'] ??
          0,
      animalNome: (map['animal'] as Map<String, dynamic>?)?['nome'] ??
          map['animal_nome'] ??
          'Desconhecido',
      tipo: map['tipo'] ?? 'Cio',
      data: DateTime.parse(map['data']),
      touro: map['touro'],
      previsaoParto: map['previsaoParto'] != null
          ? DateTime.tryParse(map['previsaoParto'])
          : null,
      status: map['status'] ?? 'Pendente',
      observacao: map['observacao'],
    );
  }
}
