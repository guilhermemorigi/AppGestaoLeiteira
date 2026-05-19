import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AnimalFormView extends StatefulWidget {
  const AnimalFormView({super.key});

  @override
  State<AnimalFormView> createState() => _AnimalFormViewState();
}

class _AnimalFormViewState extends State<AnimalFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _racaController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final animal = Animal(
        nome: _nomeController.text,
        idade: int.parse(_idadeController.text),
        raca: _racaController.text,
      );

      try {
        await _apiService.createAnimal(animal);
        if (mounted) Navigator.pop(context, true);
      } catch (_) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erro ao salvar. Verifique a conexão.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Animal'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome ou Identificação',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idadeController,
                      decoration: const InputDecoration(
                        labelText: 'Idade (anos)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _racaController,
                      decoration: const InputDecoration(
                        labelText: 'Raça',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Animal',
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
