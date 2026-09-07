import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class VaccineFormView extends StatefulWidget {
  final Animal? animal;
  const VaccineFormView({super.key, this.animal});

  @override
  State<VaccineFormView> createState() => _VaccineFormViewState();
}

class _VaccineFormViewState extends State<VaccineFormView> {
  final _formKey = GlobalKey<FormState>();
  final _loteController = TextEditingController();
  final _veterinarioController = TextEditingController();
  final _obsController = TextEditingController();
  final _apiService = ApiService();

  List<Animal> _animals = [];
  Animal? _selectedAnimal;
  String? _nomeVacina;
  final _outraVacinaController = TextEditingController();
  DateTime _dataAplicacao = DateTime.now();
  DateTime? _proximaDose;
  bool _isLoading = true;
  bool _isSaving = false;

  final _vacinasComuns = const [
    'Aftosa',
    'Brucelose',
    'Raiva',
    'Clostridiose',
    'Carbúnculo',
    'IBR / BVD',
    'Leptospirose',
    'Outra',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  @override
  void dispose() {
    _loteController.dispose();
    _veterinarioController.dispose();
    _obsController.dispose();
    _outraVacinaController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal')),
      );
      return;
    }
    final nome = _nomeVacina == 'Outra'
        ? _outraVacinaController.text.trim()
        : (_nomeVacina ?? '');
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a vacina')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final vaccine = Vaccine(
      animalId: _selectedAnimal!.id!,
      animalNome: _selectedAnimal!.nome,
      nome: nome,
      dataAplicacao: _dataAplicacao,
      proximaDose: _proximaDose,
      lote: _loteController.text.trim().isEmpty
          ? null
          : _loteController.text.trim(),
      veterinario: _veterinarioController.text.trim().isEmpty
          ? null
          : _veterinarioController.text.trim(),
      observacao: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
    );

    try {
      await _apiService.createVaccine(vaccine);
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
    return Scaffold(
      appBar: const CustomAppBar(title: 'Registrar Vacina'),
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
                        labelText: 'Animal',
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
                      value: _nomeVacina,
                      decoration: const InputDecoration(
                        labelText: 'Vacina',
                        prefixIcon: Icon(Icons.vaccines),
                      ),
                      items: _vacinasComuns
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _nomeVacina = v),
                      validator: (v) => v == null ? 'Selecione a vacina' : null,
                    ),
                    if (_nomeVacina == 'Outra') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _outraVacinaController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da vacina',
                          prefixIcon: Icon(Icons.edit),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataAplicacao,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dataAplicacao = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de aplicação',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                            DateFormat('dd/MM/yyyy').format(_dataAplicacao)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _proximaDose ?? DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _proximaDose = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Próxima dose (opcional)',
                          prefixIcon: Icon(Icons.event_repeat),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_proximaDose == null
                                ? 'Não agendada'
                                : DateFormat('dd/MM/yyyy')
                                    .format(_proximaDose!)),
                            if (_proximaDose != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _proximaDose = null),
                              )
                            else
                              const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _loteController,
                      decoration: const InputDecoration(
                        labelText: 'Lote',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _veterinarioController,
                      decoration: const InputDecoration(
                        labelText: 'Veterinário / Aplicador',
                        prefixIcon: Icon(Icons.person),
                      ),
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
                      label: const Text('Salvar Vacina'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
