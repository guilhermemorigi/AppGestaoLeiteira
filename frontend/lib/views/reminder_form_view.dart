import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReminderFormView extends StatefulWidget {
  final Reminder? reminder; // se informado, edição
  const ReminderFormView({super.key, this.reminder});

  @override
  State<ReminderFormView> createState() => _ReminderFormViewState();
}

class _ReminderFormViewState extends State<ReminderFormView> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEdit => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    if (r != null) {
      _tituloController.text = r.titulo;
      _descricaoController.text = r.descricao;
      _selectedDate = r.data;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final reminder = Reminder(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        data: _selectedDate,
        concluido: widget.reminder?.concluido ?? false,
      );

      try {
        if (_isEdit) {
          await _apiService.updateReminder(widget.reminder!.id!, reminder);
        } else {
          await _apiService.createReminder(reminder);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(describeError(e,
                    fallback: 'Erro ao salvar. Verifique a conexão.'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          CustomAppBar(title: _isEdit ? 'Editar Lembrete' : 'Novo Lembrete'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título (Ex: Vacina Aftosa)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição/Observações',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: _selectedDate.isBefore(DateTime.now())
                        ? _selectedDate
                        : DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data do Manejo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Salvar Lembrete',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
