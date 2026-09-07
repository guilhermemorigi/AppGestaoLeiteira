import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'vaccine_form_view.dart';

class VaccineListView extends StatefulWidget {
  const VaccineListView({super.key});

  @override
  State<VaccineListView> createState() => _VaccineListViewState();
}

class _VaccineListViewState extends State<VaccineListView> {
  List<Vaccine> _vaccines = [];
  bool _isLoading = true;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAllVaccines();
      if (!mounted) return;
      setState(() {
        _vaccines = data;
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
      MaterialPageRoute(builder: (_) => const VaccineFormView()),
    );
    if (result == true) _refresh();
  }

  bool _isDoseProxima(Vaccine v) {
    if (v.proximaDose == null) return false;
    final diff = v.proximaDose!.difference(DateTime.now()).inDays;
    return diff <= 30;
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _vaccines.where(_isDoseProxima).length;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Vacinação'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (pendentes > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.orange.withOpacity(0.12),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active,
                            color: AppTheme.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$pendentes dose(s) próxima(s) do vencimento (30 dias)',
                            style: const TextStyle(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _vaccines.isEmpty
                      ? const EmptyState(
                          icon: Icons.vaccines_outlined,
                          message: 'Nenhuma vacina registrada',
                          hint:
                              'Controle o calendário de vacinação do rebanho.',
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _vaccines.length,
                            itemBuilder: (context, i) {
                              final v = _vaccines[i];
                              final proxima = _isDoseProxima(v);
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppTheme.teal.withOpacity(0.12),
                                    child: const Icon(Icons.vaccines,
                                        color: AppTheme.teal),
                                  ),
                                  title: Text(v.nome,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                          '${v.animalNome} • Aplicada ${DateFormat('dd/MM/yyyy').format(v.dataAplicacao)}'),
                                      if (v.proximaDose != null)
                                        Row(
                                          children: [
                                            Icon(Icons.event_repeat,
                                                size: 14,
                                                color: proxima
                                                    ? AppTheme.orange
                                                    : Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Próxima: ${DateFormat('dd/MM/yyyy').format(v.proximaDose!)}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: proxima
                                                      ? AppTheme.orange
                                                      : Colors.grey[700],
                                                  fontWeight: proxima
                                                      ? FontWeight.bold
                                                      : FontWeight.normal),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey),
                                    onPressed: () => _confirmDelete(v),
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
        label: const Text('Nova Vacina'),
        backgroundColor: AppTheme.teal,
      ),
    );
  }

  void _confirmDelete(Vaccine v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Vacina'),
        content: Text('Deseja excluir a vacina "${v.nome}" de ${v.animalNome}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteVaccine(v.id!);
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
