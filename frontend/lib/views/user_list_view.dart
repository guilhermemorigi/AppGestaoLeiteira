import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'user_form_view.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key});

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  List<User> _users = [];
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
      final data = await _apiService.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = data;
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

  Future<void> _openForm({User? user}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserFormView(user: user)),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const EmptyState(
                  icon: Icons.group_outlined,
                  message: 'Nenhum usuário cadastrado',
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _users.length,
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      final isAdmin = u.role == 'ADMIN';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () => _openForm(user: u),
                          leading: CircleAvatar(
                            backgroundColor: (isAdmin
                                    ? AppTheme.orange
                                    : AppTheme.primary)
                                .withOpacity(0.15),
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: isAdmin
                                  ? AppTheme.orange
                                  : AppTheme.primary,
                            ),
                          ),
                          title: Text(
                            u.nomeCompleto?.isNotEmpty == true
                                ? u.nomeCompleto!
                                : u.username,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${u.username}'),
                              if (u.email?.isNotEmpty == true)
                                Text(u.email!,
                                    style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  StatusChip(isAdmin ? 'Administrador' : 'Operador'),
                                  const SizedBox(width: 6),
                                  if (!u.ativo)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Inativo',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () => _confirmDelete(u),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
      ),
    );
  }

  void _confirmDelete(User u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Usuário'),
        content: Text('Deseja excluir o usuário "${u.username}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteUser(u.id!);
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
