import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ReproductionFormView extends StatefulWidget {
  final Animal? animal;
  const ReproductionFormView({super.key, this.animal});

  @override
  State<ReproductionFormView> createState() => _ReproductionFormViewState();
}

class _ReproductionFormViewState extends State<ReproductionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _touroController = TextEditingController();
  final _obsController = TextEditingController();
  final _apiService = ApiService();

  List<Animal> _animals = [];
  Animal? _selectedAnimal;
  String _tipo = 'Cio';
  String _status = 'Pendente';
  DateTime _data = DateTime.now();
  DateTime? _previsaoParto;
  bool _isLoading = true;
  bool _isSaving = false;

  // Gestação bovina ~283 dias
  static const int _gestacaoDias = 283;

  final _tipos = const [
    'Cio',
    'Cobertura',
    'Inseminação',
    'Diagnóstico Gestação',
    'Parto',
  ];
  final _statuses = const [
    'Pendente',
    'Confirmada',
    'Prenhe',
    'Vazia',
    'Parida',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  @override
  void dispose() {
    _touroController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    try {
      final animals = await _apiService.getAllAnimals();
      setState(() {
        _animals = animals;
        if (widget.animal != null) {
          _selectedAnimal = animals.firstWhere(
            (a) => a.id == widget.animal!.id,
            orElse: () => widget.animal!,
          );
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar animais.')),
        );
      }
    }
  }

  void _sugerirPrevisaoParto() {
    // Ao registrar cobertura/inseminação, sugere previsão de parto
    if (_tipo == 'Cobertura' || _tipo == 'Inseminação') {
      setState(() {
        _previsaoParto = _data.add(const Duration(days: _gestacaoDias));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final r = Reproduction(
      animalId: _selectedAnimal!.id!,
      animalNome: _selectedAnimal!.nome,
      tipo: _tipo,
      data: _data,
      touro: _touroController.text.trim().isEmpty
          ? null
          : _touroController.text.trim(),
      previsaoParto: _previsaoParto,
      status: _status,
      observacao: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
    );

    try {
      await _apiService.createReproduction(r);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Verifique a conexão.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostrarTouro = _tipo == 'Cobertura' || _tipo == 'Inseminação';

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Reprodução')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<Animal>(
                      value: _selectedAnimal,
                      decoration: const InputDecoration(
                        labelText: 'Animal (matriz)',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      items: _animals
                          .map((a) => DropdownMenuItem(
                              value: a, child: Text(a.nome)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAnimal = v),
                      validator: (v) => v == null ? 'Selecione um animal' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Evento',
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      items: _tipos
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _tipo = v!);
                        _sugerirPrevisaoParto();
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _data,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _data = picked);
                          _sugerirPrevisaoParto();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data do evento',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_data)),
                      ),
                    ),
                    if (mostrarTouro) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _touroController,
                        decoration: const InputDecoration(
                          labelText: 'Touro / Sêmen',
                          prefixIcon: Icon(Icons.male),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _previsaoParto ??
                                _data.add(const Duration(days: _gestacaoDias)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _previsaoParto = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Previsão de parto',
                            prefixIcon: Icon(Icons.child_friendly),
                            helperText: 'Calculada automaticamente (~283 dias)',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_previsaoParto == null
                                  ? 'Não definida'
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_previsaoParto!)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _statuses
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _obsController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('Salvar Registro'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
