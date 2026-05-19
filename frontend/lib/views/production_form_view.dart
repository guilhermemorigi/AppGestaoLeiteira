import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ProductionFormView extends StatefulWidget {
  const ProductionFormView({super.key});

  @override
  State<ProductionFormView> createState() => _ProductionFormViewState();
}

class _ProductionFormViewState extends State<ProductionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  final _apiService = ApiService();
  Animal? _selectedAnimal;
  DateTime _selectedDate = DateTime.now();
  List<Animal> _animalsAvailable = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    try {
      final animals = await _apiService.getAllAnimals();
      setState(() {
        _animalsAvailable = animals;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao carregar animais do servidor.')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAnimal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um animal')),
        );
        return;
      }

      setState(() => _isSaving = true);
      final production = Production(
        animalId: _selectedAnimal!.id!,
        animalNome: _selectedAnimal!.nome,
        data: _selectedDate,
        quantidade:
            double.parse(_quantidadeController.text.replaceAll(',', '.')),
      );

      try {
        await _apiService.createProduction(production);
        if (mounted) {
          setState(() => _isSaving = false);
          Navigator.pop(context, true);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erro ao salvar produção. Verifique a conexão.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Produção'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<Animal>(
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Animal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      items: _animalsAvailable
                          .map((a) =>
                              DropdownMenuItem(value: a, child: Text(a.nome)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAnimal = value),
                      validator: (value) =>
                          value == null ? 'Selecione um animal' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null)
                          setState(() => _selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data da Produção',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate)),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de Leite (L)',
                        hintText: '0,0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.water_drop),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Campo obrigatório';
                        final parsed =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (parsed == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('Salvar Produção',
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
