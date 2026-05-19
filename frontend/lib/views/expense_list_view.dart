import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'expense_form_view.dart';

class ExpenseListView extends StatefulWidget {
  const ExpenseListView({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  List<Expense> _expenses = [];
  double _total = 0;
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
      final data = await _apiService.getAllExpenses();
      if (!mounted) return;
      setState(() {
        _expenses = data;
        _total = data.fold(0.0, (sum, e) => sum + e.valor);
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total de Gastos:',
                          style: TextStyle(fontSize: 18)),
                      Text(
                        currencyFormat.format(_total),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: _expenses.isEmpty
                        ? const Center(child: Text('Nenhum gasto registrado'))
                        : ListView.builder(
                            itemCount: _expenses.length,
                            itemBuilder: (context, index) {
                              final ex = _expenses[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red[100],
                                  child: const Icon(Icons.money_off,
                                      color: Colors.red),
                                ),
                                title: Text(ex.descricao),
                                subtitle: Text(
                                    '${ex.categoria} | ${DateFormat('dd/MM/yyyy').format(ex.data)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currencyFormat.format(ex.valor),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () => _confirmDelete(ex),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseFormView()),
          );
          if (result == true) _refreshData();
        },
        label: const Text('Novo Gasto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
      ),
    );
  }

  void _confirmDelete(Expense ex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Gasto'),
        content: Text('Deseja realmente excluir o gasto "${ex.descricao}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteExpense(ex.id!);
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
