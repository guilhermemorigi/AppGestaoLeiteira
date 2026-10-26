import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'reproduction_form_view.dart';

class ReproductionListView extends StatefulWidget {
  const ReproductionListView({super.key});

  @override
  State<ReproductionListView> createState() => _ReproductionListViewState();
}

class _ReproductionListViewState extends State<ReproductionListView> {
  List<Reproduction> _records = [];
  bool _isLoading = true;
  final _apiService = ApiService();

  final _tipoIcons = const {
    'Cio': Icons.favorite,
    'Cobertura': Icons.male,
    'Inseminação': Icons.science,
    'Diagnóstico Gestação': Icons.pregnant_woman,
    'Parto': Icons.child_friendly,
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
      final data = await _apiService.getAllReproduction();
      if (!mounted) return;
      setState(() {
        _records = data;
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

  Future<void> _openForm([Reproduction? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReproductionFormView(record: item)),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final prenhes = _records
        .where((r) => r.status == 'Prenhe' || r.status == 'Confirmada')
        .length;
    final partosProximos = _records.where((r) {
      if (r.previsaoParto == null) return false;
      final diff = r.previsaoParto!.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 30;
    }).length;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reprodução'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.purple.withOpacity(0.05),
                  child: Row(
                    children: [
                      Expanded(
                        child: HeaderStat(
                            'Prenhes / Confirmadas', '$prenhes', AppTheme.blue),
                      ),
                      Container(width: 1, height: 36, color: Colors.grey[300]),
                      Expanded(
                        child: HeaderStat('Partos ≤ 30 dias', '$partosProximos',
                            AppTheme.purple),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _records.isEmpty
                      ? const EmptyState(
                          icon: Icons.favorite_outline,
                          message: 'Nenhum registro reprodutivo',
                          hint: 'Acompanhe cio, cobertura, gestação e partos.',
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _records.length,
                            itemBuilder: (context, i) {
                              final r = _records[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  onTap: () => _openForm(r),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppTheme.purple.withOpacity(0.12),
                                    child: Icon(
                                        _tipoIcons[r.tipo] ?? Icons.favorite,
                                        color: AppTheme.purple),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            '${r.animalNome} • ${r.tipo}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      StatusChip(r.status),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(DateFormat('dd/MM/yyyy')
                                          .format(r.data)),
                                      if (r.touro != null &&
                                          r.touro!.isNotEmpty)
                                        Text('Touro/Sêmen: ${r.touro}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      if (r.previsaoParto != null)
                                        Text(
                                          'Previsão de parto: ${DateFormat('dd/MM/yyyy').format(r.previsaoParto!)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.purple,
                                              fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey),
                                    onPressed: () => _confirmDelete(r),
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
        label: const Text('Novo Registro'),
        backgroundColor: AppTheme.purple,
      ),
    );
  }

  void _confirmDelete(Reproduction r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro'),
        content:
            Text('Deseja excluir o registro de ${r.tipo} de ${r.animalNome}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteReproduction(r.id!);
                _refresh();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            describeError(e, fallback: 'Erro ao excluir.'))),
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
