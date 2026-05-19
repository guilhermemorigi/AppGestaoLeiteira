import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'production_form_view.dart';

class ProductionListView extends StatefulWidget {
  const ProductionListView({super.key});

  @override
  State<ProductionListView> createState() => _ProductionListViewState();
}

class _ProductionListViewState extends State<ProductionListView> {
  List<Production> _productions = [];
  List<Animal> _animalsAvailable = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final productions = await _apiService.getAllProduction();
      final animals = await _apiService.getAllAnimals();
      if (!mounted) return;
      setState(() {
        _productions = productions;
        _animalsAvailable = animals;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao conectar com o servidor.')),
      );
    }
  }

  Future<void> _navigateToForm() async {
    if (_animalsAvailable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um animal primeiro!')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductionFormView()),
    );

    if (result == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('pt_BR');

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _productions.isEmpty
              ? const Center(child: Text('Nenhum registro de produção'))
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    itemCount: _productions.length,
                    itemBuilder: (context, index) {
                      final p = _productions[index];
                      return ListTile(
                        leading:
                            const Icon(Icons.water_drop, color: Colors.blue),
                        title: Text(
                            '${p.animalNome} - ${numberFormat.format(p.quantidade)} L'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(p.data)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _confirmDelete(p),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        label: const Text('Lançar Produção'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Production p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro'),
        content:
            const Text('Deseja realmente excluir este registro de produção?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteProduction(p.id!);
                _refreshData();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erro ao excluir. Verifique a conexão.')),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
