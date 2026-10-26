import 'package:intl/intl.dart';

// Formato de data aceito/gerado pelo backend (LocalDateTime em ISO 8601)
final _apiDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

String _toApiDate(DateTime date) => _apiDateFormat.format(date);
String? _toApiDateOrNull(DateTime? date) =>
    date == null ? null : _apiDateFormat.format(date);
DateTime? _parseDateOrNull(dynamic value) =>
    value == null ? null : DateTime.tryParse(value as String);

/// Referência ao animal no formato esperado pela API: {"animal": {"id": X}}
Map<String, dynamic> _animalRef(int animalId) => {'id': animalId};

int _animalIdFrom(Map<String, dynamic> map) =>
    (map['animal'] as Map<String, dynamic>?)?['id'] ?? 0;

String _animalNomeFrom(Map<String, dynamic> map) =>
    (map['animal'] as Map<String, dynamic>?)?['nome'] ?? 'Desconhecido';

class User {
  final int? id;
  final String username;
  final String password; // nunca retornada pela API; usada apenas no envio
  final String? nomeCompleto;
  final String? email;
  final String? telefone;
  final String role; // ADMIN, OPERADOR
  final bool ativo;

  User({
    this.id,
    required this.username,
    this.password = '',
    this.nomeCompleto,
    this.email,
    this.telefone,
    this.role = 'OPERADOR',
    this.ativo = true,
  });

  Map<String, dynamic> toJson() {
    return {
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
      nomeCompleto: map['nomeCompleto'],
      email: map['email'],
      telefone: map['telefone'],
      role: map['role'] ?? 'OPERADOR',
      ativo: map['ativo'] ?? true,
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

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'idade': idade,
      'raca': raca,
      'numeroBrinco': numeroBrinco,
      'sexo': sexo,
      'peso': peso,
      'dataNascimento': _toApiDateOrNull(dataNascimento),
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
      dataNascimento: _parseDateOrNull(map['dataNascimento']),
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

  Map<String, dynamic> toJson() {
    return {
      'animal': _animalRef(animalId),
      'data': _toApiDate(data),
      'quantidade': quantidade,
    };
  }

  factory Production.fromMap(Map<String, dynamic> map) {
    return Production(
      id: map['id'],
      animalId: _animalIdFrom(map),
      animalNome: _animalNomeFrom(map),
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
  final String? origem; // null = manual; SAUDE = gerada por registro de saúde

  Expense({
    this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.categoria,
    this.origem,
  });

  bool get automatica => origem != null;

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'valor': valor,
      'data': _toApiDate(data),
      'categoria': categoria,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] as num).toDouble(),
      data: DateTime.parse(map['data']),
      categoria: map['categoria'] ?? 'Outros',
      origem: map['origem'],
    );
  }
}

class Reminder {
  final int? id;
  final String titulo;
  final String descricao;
  final DateTime data;
  final bool concluido;
  final String? origem; // null = manual; VACINA = próxima dose de vacina

  Reminder({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.data,
    this.concluido = false,
    this.origem,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'data': _toApiDate(data),
      'concluido': concluido,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      data: DateTime.parse(map['data']),
      concluido: map['concluido'] ?? false,
      origem: map['origem'],
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

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'categoria': categoria,
      'quantidade': quantidade,
      'unidade': unidade,
      'quantidadeMinima': quantidadeMinima,
      'precoUnitario': precoUnitario,
      'validade': _toApiDateOrNull(validade),
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
      validade: _parseDateOrNull(map['validade']),
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

  Map<String, dynamic> toJson() {
    return {
      'animal': _animalRef(animalId),
      'tipo': tipo,
      'descricao': descricao,
      'medicamento': medicamento,
      'veterinario': veterinario,
      'data': _toApiDate(data),
      'dataFim': _toApiDateOrNull(dataFim),
      'custo': custo,
      'status': status,
      'observacao': observacao,
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      animalId: _animalIdFrom(map),
      animalNome: _animalNomeFrom(map),
      tipo: map['tipo'] ?? 'Tratamento',
      descricao: map['descricao'] ?? '',
      medicamento: map['medicamento'],
      veterinario: map['veterinario'],
      data: DateTime.parse(map['data']),
      dataFim: _parseDateOrNull(map['dataFim']),
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

  Map<String, dynamic> toJson() {
    return {
      'animal': _animalRef(animalId),
      'nome': nome,
      'dataAplicacao': _toApiDate(dataAplicacao),
      'proximaDose': _toApiDateOrNull(proximaDose),
      'lote': lote,
      'veterinario': veterinario,
      'observacao': observacao,
    };
  }

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'],
      animalId: _animalIdFrom(map),
      animalNome: _animalNomeFrom(map),
      nome: map['nome'] ?? '',
      dataAplicacao: DateTime.parse(map['dataAplicacao']),
      proximaDose: _parseDateOrNull(map['proximaDose']),
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

  Map<String, dynamic> toJson() {
    return {
      'animal': _animalRef(animalId),
      'tipo': tipo,
      'data': _toApiDate(data),
      'touro': touro,
      'previsaoParto': _toApiDateOrNull(previsaoParto),
      'status': status,
      'observacao': observacao,
    };
  }

  factory Reproduction.fromMap(Map<String, dynamic> map) {
    return Reproduction(
      id: map['id'],
      animalId: _animalIdFrom(map),
      animalNome: _animalNomeFrom(map),
      tipo: map['tipo'] ?? 'Cio',
      data: DateTime.parse(map['data']),
      touro: map['touro'],
      previsaoParto: _parseDateOrNull(map['previsaoParto']),
      status: map['status'] ?? 'Pendente',
      observacao: map['observacao'],
    );
  }
}
