import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'animal_detail_view.dart';
import 'animal_form_view.dart';

class AnimalListView extends StatefulWidget {
  const AnimalListView({super.key});

  @override
  State<AnimalListView> createState() => _AnimalListViewState();
}

class _AnimalListViewState extends State<AnimalListView> {
  List<Animal> _animals = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _refreshAnimals();
  }

  Future<void> _refreshAnimals() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAllAnimals();
      setState(() {
        _animals = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao conectar com o servidor.')),
        );
      }
    }
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnimalFormView()),
    );

    if (result == true) {
      _refreshAnimals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _animals.isEmpty
              ? const Center(child: Text('Nenhum animal cadastrado'))
              : RefreshIndicator(
                  onRefresh: _refreshAnimals,
                  child: ListView.builder(
                    itemCount: _animals.length,
                    itemBuilder: (context, index) {
                      final animal = _animals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimalDetailView(animal: animal),
                              ),
                            );
                          },
                          leading: CircleAvatar(child: Icon(MdiIcons.cow)),
                          title: Text(animal.nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text(
                              'Raça: ${animal.raca} | Idade: ${animal.idade} anos'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(animal),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        label: const Text('Novo Animal'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Animal animal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Animal'),
        content: Text(
            'Deseja realmente excluir ${animal.nome}? Isso removerá todo o histórico de produção deste animal.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _apiService.deleteAnimal(animal.id!);
                _refreshAnimals();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Animal excluído com sucesso')),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Erro ao excluir. Verifique a conexão.')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
