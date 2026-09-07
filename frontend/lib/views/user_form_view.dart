import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class UserFormView extends StatefulWidget {
  final User? user; // se informado, edição
  const UserFormView({super.key, this.user});

  @override
  State<UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  String _role = 'OPERADOR';
  bool _ativo = true;
  bool _isObscure = true;
  bool _isSaving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _usernameController.text = u.username;
      _nomeController.text = u.nomeCompleto ?? '';
      _emailController.text = u.email ?? '';
      _telefoneController.text = u.telefone ?? '';
      _role = u.role;
      _ativo = u.ativo;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = User(
      id: widget.user?.id,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      nomeCompleto: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      telefone: _telefoneController.text.trim(),
      role: _role,
      ativo: _ativo,
    );

    try {
      if (_isEdit) {
        await _apiService.updateUser(widget.user!.id!, user);
      } else {
        await _apiService.createUser(user);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao salvar. Usuário pode já existir.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar Usuário' : 'Novo Usuário')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuário (login)',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: _isEdit
                      ? 'Nova senha (deixe vazio p/ manter)'
                      : 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
                validator: (v) {
                  if (_isEdit) return null; // opcional na edição
                  if (v == null || v.length < 4) {
                    return 'Mínimo de 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Perfil de acesso',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'ADMIN', child: Text('Administrador')),
                  DropdownMenuItem(
                      value: 'OPERADOR', child: Text('Operador')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Usuário ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
                secondary: const Icon(Icons.toggle_on),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isEdit ? 'Salvar Alterações' : 'Cadastrar Usuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
