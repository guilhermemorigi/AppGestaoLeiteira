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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(describeError(e,
                fallback: 'Erro ao conectar com o servidor.'))),
      );
    }
  }

  Future<void> _openForm([Expense? expense]) async {
    if (expense != null && expense.automatica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gasto gerado por um registro de saúde. '
                'Altere o custo em Saúde & Tratamentos.')),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ExpenseFormView(expense: expense)),
    );
    if (result == true) _refreshData();
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
                      const Flexible(
                        child: Text('Total de Gastos:',
                            style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      // Totais grandes encolhem em vez de empurrar o rótulo
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            currencyFormat.format(_total),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                        ),
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
                                onTap: () => _openForm(ex),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red[100],
                                  child: Icon(
                                      ex.automatica
                                          ? Icons.health_and_safety
                                          : Icons.money_off,
                                      color: Colors.red),
                                ),
                                title: Text(ex.descricao,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    '${ex.categoria} | ${DateFormat('dd/MM/yyyy').format(ex.data)}'
                                    '${ex.automatica ? ' | automático' : ''}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Valor com largura máxima: encolhe se for muito grande
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 110),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          currencyFormat.format(ex.valor),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!ex.automatica)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        onPressed: () => _confirmDelete(ex),
                                      )
                                    else
                                      const SizedBox(width: 48),
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
        onPressed: () => _openForm(),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Gasto'),
        content: Text('Deseja realmente excluir o gasto "${ex.descricao}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteExpense(ex.id!);
                _refreshData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(describeError(e,
                            fallback:
                                'Erro ao excluir. Verifique a conexão.'))),
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
