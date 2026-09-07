import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'health_form_view.dart';

class HealthListView extends StatefulWidget {
  const HealthListView({super.key});

  @override
  State<HealthListView> createState() => _HealthListViewState();
}

class _HealthListViewState extends State<HealthListView> {
  List<HealthRecord> _records = [];
  bool _isLoading = true;
  final _apiService = ApiService();

  final _tipoIcons = const {
    'Doença': Icons.sick,
    'Tratamento': Icons.healing,
    'Exame': Icons.biotech,
    'Cirurgia': Icons.medical_services,
    'Vermífugo': Icons.bug_report,
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
      final data = await _apiService.getAllHealth();
      if (!mounted) return;
      setState(() {
        _records = data;
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

  Future<void> _openForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthFormView()),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final emAndamento =
        _records.where((r) => r.status == 'Em andamento').length;
    final custoTotal = _records.fold<double>(0, (s, r) => s + r.custo);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Saúde & Tratamentos'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.red.withOpacity(0.05),
                  child: Row(
                    children: [
                      Expanded(
                        child: _stat('Em andamento', '$emAndamento',
                            AppTheme.orange),
                      ),
                      Container(
                          width: 1, height: 36, color: Colors.grey[300]),
                      Expanded(
                        child: _stat('Custo total',
                            currency.format(custoTotal), AppTheme.red),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _records.isEmpty
                      ? const EmptyState(
                          icon: Icons.health_and_safety_outlined,
                          message: 'Nenhum registro de saúde',
                          hint:
                              'Registre doenças, tratamentos e exames dos animais.',
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
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppTheme.red.withOpacity(0.1),
                                    child: Icon(
                                        _tipoIcons[r.tipo] ??
                                            Icons.local_hospital,
                                        color: AppTheme.red),
                                  ),
                                  title: Text(r.descricao,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                          '${r.animalNome} • ${r.tipo} • ${DateFormat('dd/MM/yyyy').format(r.data)}'),
                                      if (r.medicamento != null &&
                                          r.medicamento!.isNotEmpty)
                                        Text('Med.: ${r.medicamento}',
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      const SizedBox(height: 6),
                                      StatusChip(r.status),
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
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Novo Registro'),
        backgroundColor: AppTheme.red,
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
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

  void _confirmDelete(HealthRecord r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro'),
        content: Text('Deseja excluir o registro "${r.descricao}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteHealth(r.id!);
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
