import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class _BrazilianCurrencyFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,##0.00', 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final value = int.parse(digits) / 100;
    final formatted = _fmt.format(value);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpenseFormView extends StatefulWidget {
  final Expense? expense; // se informado, edição
  const ExpenseFormView({super.key, this.expense});

  @override
  State<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends State<ExpenseFormView> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Ração';
  bool _isSaving = false;

  final List<String> _categories = [
    'Ração',
    'Vacina/Medicamento',
    'Veterinário',
    'Manutenção',
    'Combustível',
    'Mão de Obra',
    'Outros',
  ];

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _descricaoController.text = e.descricao;
      _valorController.text = NumberFormat('#,##0.00', 'pt_BR').format(e.valor);
      _selectedDate = e.data;
      _selectedCategory = e.categoria;
      // Categoria antiga/fora da lista continua selecionável na edição
      if (!_categories.contains(e.categoria)) _categories.add(e.categoria);
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final digits = _valorController.text.replaceAll(RegExp(r'[^\d]'), '');
      final expense = Expense(
        descricao: _descricaoController.text.trim(),
        valor: digits.isEmpty ? 0 : int.parse(digits) / 100,
        data: _selectedDate,
        categoria: _selectedCategory,
      );

      try {
        if (_isEdit) {
          await _apiService.updateExpense(widget.expense!.id!, expense);
        } else {
          await _apiService.createExpense(expense);
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
      appBar: CustomAppBar(title: _isEdit ? 'Editar Gasto' : 'Lançar Gasto'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: '0,00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_BrazilianCurrencyFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (digits.isEmpty || int.parse(digits) == 0) {
                    return 'Informe um valor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && mounted) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data do Gasto',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
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
                label:
                    const Text('Salvar Gasto', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
