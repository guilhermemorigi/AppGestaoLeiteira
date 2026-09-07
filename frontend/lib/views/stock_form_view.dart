import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StockFormView extends StatefulWidget {
  final StockItem? item; // se informado, edição
  const StockFormView({super.key, this.item});

  @override
  State<StockFormView> createState() => _StockFormViewState();
}

class _StockFormViewState extends State<StockFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _minimaController = TextEditingController();
  final _precoController = TextEditingController();
  final _obsController = TextEditingController();
  final _apiService = ApiService();

  String _categoria = 'Ração';
  String _unidade = 'kg';
  DateTime? _validade;
  bool _isSaving = false;

  final _categorias = const [
    'Ração',
    'Medicamento',
    'Vacina',
    'Higiene',
    'Equipamento',
    'Suplemento',
    'Outros',
  ];
  final _unidades = const ['kg', 'L', 'un', 'saco', 'dose', 'g', 'mL'];

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    if (it != null) {
      _nomeController.text = it.nome;
      _quantidadeController.text = _fmtNum(it.quantidade);
      _minimaController.text = _fmtNum(it.quantidadeMinima);
      _precoController.text = _fmtNum(it.precoUnitario);
      _obsController.text = it.observacao ?? '';
      _categoria = _categorias.contains(it.categoria) ? it.categoria : 'Outros';
      _unidade = _unidades.contains(it.unidade) ? it.unidade : 'un';
      _validade = it.validade;
    }
  }

  String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _minimaController.dispose();
    _precoController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final item = StockItem(
      id: widget.item?.id,
      nome: _nomeController.text.trim(),
      categoria: _categoria,
      quantidade: _parse(_quantidadeController.text),
      unidade: _unidade,
      quantidadeMinima: _parse(_minimaController.text),
      precoUnitario: _parse(_precoController.text),
      validade: _validade,
      observacao: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
    );

    try {
      if (_isEdit) {
        await _apiService.updateStock(widget.item!.id!, item);
      } else {
        await _apiService.createStock(item);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Verifique a conexão.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar Item' : 'Novo Item de Estoque')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do item',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unidade,
                      decoration: const InputDecoration(labelText: 'Unid.'),
                      items: _unidades
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unidade = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minimaController,
                      decoration: const InputDecoration(
                        labelText: 'Estoque mínimo',
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      decoration: const InputDecoration(
                        labelText: 'Preço unit. (R\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _validade ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _validade = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Validade (opcional)',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_validade == null
                          ? 'Sem validade'
                          : DateFormat('dd/MM/yyyy').format(_validade!)),
                      if (_validade != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _validade = null),
                        )
                      else
                        const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obsController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isEdit ? 'Salvar Alterações' : 'Salvar Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
