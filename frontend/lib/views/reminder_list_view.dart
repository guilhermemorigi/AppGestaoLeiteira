import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'reminder_form_view.dart';

class ReminderListView extends StatefulWidget {
  const ReminderListView({super.key});

  @override
  State<ReminderListView> createState() => _ReminderListViewState();
}

class _ReminderListViewState extends State<ReminderListView> {
  List<Reminder> _reminders = [];
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
      final data = await _apiService.getAllReminders();
      if (!mounted) return;
      setState(() {
        _reminders = data;
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const Center(
                  child: Text('Nenhum lembrete para os próximos dias.'))
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final r = _reminders[index];
                      final isOverdue =
                          r.data.isBefore(DateTime.now()) && !r.concluido;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.event_note,
                            color: isOverdue ? Colors.red : Colors.green,
                          ),
                          title: Text(
                            r.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverdue ? Colors.red : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.descricao),
                              Text(
                                'Data: ${DateFormat('dd/MM/yyyy').format(r.data)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOverdue ? Colors.red : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _confirmDelete(r),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReminderFormView()),
          );
          if (result == true) _refreshData();
        },
        label: const Text('Novo Lembrete'),
        icon: const Icon(Icons.add_alert),
      ),
    );
  }

  void _confirmDelete(Reminder r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Lembrete'),
        content: Text('Deseja realmente excluir o lembrete "${r.titulo}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteReminder(r.id!);
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
