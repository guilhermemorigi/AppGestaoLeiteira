import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'stock_form_view.dart';

class StockListView extends StatefulWidget {
  const StockListView({super.key});

  @override
  State<StockListView> createState() => _StockListViewState();
}

class _StockListViewState extends State<StockListView> {
  List<StockItem> _items = [];
  bool _isLoading = true;
  String _filter = 'Todos';
  final _apiService = ApiService();

  final _icons = const {
    'Ração': Icons.grass,
    'Medicamento': Icons.medication,
    'Vacina': Icons.vaccines,
    'Higiene': Icons.cleaning_services,
    'Equipamento': Icons.build,
    'Suplemento': Icons.science,
    'Outros': Icons.inventory_2,
  };

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAllStock();
      if (!mounted) return;
      setState(() {
        _items = data;
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

  Future<void> _openForm({StockItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockFormView(item: item)),
    );
    if (result == true) _refresh();
  }

  Future<void> _adjust(StockItem item, double delta) async {
    try {
      await _apiService.adjustStock(item.id!, delta);
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao ajustar quantidade.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final categorias = ['Todos', ..._items.map((e) => e.categoria).toSet()];
    final filtered = _filter == 'Todos'
        ? _items
        : _items.where((e) => e.categoria == _filter).toList();
    final valorTotal = _items.fold<double>(0, (s, e) => s + e.valorTotal);
    final lowCount = _items.where((e) => e.estoqueBaixo).length;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Estoque / Insumos'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withOpacity(0.06),
                  child: Row(
                    children: [
                      Expanded(
                        child: _headerStat('Valor em estoque',
                            currency.format(valorTotal), AppTheme.primary),
                      ),
                      Container(
                          width: 1, height: 36, color: Colors.grey[300]),
                      Expanded(
                        child: _headerStat(
                            'Estoque baixo',
                            '$lowCount ${lowCount == 1 ? "item" : "itens"}',
                            lowCount > 0 ? AppTheme.red : AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                if (categorias.length > 1)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: categorias
                          .map((c) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6),
                                child: ChoiceChip(
                                  label: Text(c),
                                  selected: _filter == c,
                                  onSelected: (_) =>
                                      setState(() => _filter = c),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          message: 'Nenhum item em estoque',
                          hint: 'Toque em "Novo Item" para cadastrar insumos.',
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  onTap: () => _openForm(item: item),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppTheme.primary.withOpacity(0.1),
                                    child: Icon(
                                        _icons[item.categoria] ??
                                            Icons.inventory_2,
                                        color: AppTheme.primary),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(item.nome,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      if (item.estoqueBaixo)
                                        const Icon(Icons.warning_amber,
                                            color: AppTheme.red, size: 18),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${item.categoria} • ${_fmt(item.quantidade)} ${item.unidade}'),
                                      if (item.precoUnitario > 0)
                                        Text(
                                            'Total: ${currency.format(item.valorTotal)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.primary)),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        color: AppTheme.red,
                                        onPressed: () => _adjust(item, -1),
                                        tooltip: 'Retirar 1',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        color: AppTheme.primary,
                                        onPressed: () => _adjust(item, 1),
                                        tooltip: 'Adicionar 1',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.grey),
                                        onPressed: () => _confirmDelete(item),
                                      ),
                                    ],
                                  ),
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
        icon: const Icon(Icons.add),
        label: const Text('Novo Item'),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _confirmDelete(StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Item'),
        content: Text('Deseja excluir "${item.nome}" do estoque?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteStock(item.id!);
                _refresh();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao excluir.')),
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
