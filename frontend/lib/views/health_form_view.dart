import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HealthFormView extends StatefulWidget {
  final Animal? animal; // pré-selecionado ao vir da ficha do animal
  final HealthRecord? record; // se informado, edição
  const HealthFormView({super.key, this.animal, this.record});

  @override
  State<HealthFormView> createState() => _HealthFormViewState();
}

class _HealthFormViewState extends State<HealthFormView> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _medicamentoController = TextEditingController();
  final _veterinarioController = TextEditingController();
  final _custoController = TextEditingController();
  final _obsController = TextEditingController();
  final _apiService = ApiService();

  List<Animal> _animals = [];
  Animal? _selectedAnimal;
  String _tipo = 'Tratamento';
  String _status = 'Em andamento';
  DateTime _data = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  final _tipos = const [
    'Doença',
    'Tratamento',
    'Exame',
    'Cirurgia',
    'Vermífugo',
  ];

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    if (r != null) {
      _descricaoController.text = r.descricao;
      _medicamentoController.text = r.medicamento ?? '';
      _veterinarioController.text = r.veterinario ?? '';
      _custoController.text =
          r.custo > 0 ? r.custo.toStringAsFixed(2).replaceAll('.', ',') : '';
      _obsController.text = r.observacao ?? '';
      _tipo = _tipos.contains(r.tipo) ? r.tipo : _tipo;
      _status = r.status;
      _data = r.data;
    }
    _loadAnimals();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _medicamentoController.dispose();
    _veterinarioController.dispose();
    _custoController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    try {
      final animals = await _apiService.getAllAnimals();
      final preSelecionado = widget.record?.animalId ?? widget.animal?.id;
      if (!mounted) return;
      setState(() {
        _animals = animals;
        _selectedAnimal =
            animals.where((a) => a.id == preSelecionado).firstOrNull;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  describeError(e, fallback: 'Erro ao carregar animais.'))),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um animal')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final record = HealthRecord(
      animalId: _selectedAnimal!.id!,
      animalNome: _selectedAnimal!.nome,
      tipo: _tipo,
      descricao: _descricaoController.text.trim(),
      medicamento: _medicamentoController.text.trim().isEmpty
          ? null
          : _medicamentoController.text.trim(),
      veterinario: _veterinarioController.text.trim().isEmpty
          ? null
          : _veterinarioController.text.trim(),
      data: _data,
      dataFim: widget.record?.dataFim,
      custo: double.tryParse(_custoController.text.replaceAll(',', '.')) ?? 0,
      status: _status,
      observacao: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
    );

    try {
      if (_isEdit) {
        await _apiService.updateHealth(widget.record!.id!, record);
      } else {
        await _apiService.createHealth(record);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: _isEdit
              ? 'Editar Saúde/Tratamento'
              : 'Registrar Saúde/Tratamento'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<Animal>(
                      isExpanded: true,
                      value: _selectedAnimal,
                      decoration: const InputDecoration(
                        labelText: 'Animal',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      items: _animals
                          .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.nome,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAnimal = v),
                      validator: (v) =>
                          v == null ? 'Selecione um animal' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                      items: _tipos
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição / Diagnóstico',
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _medicamentoController,
                      decoration: const InputDecoration(
                        labelText: 'Medicamento / Dosagem',
                        prefixIcon: Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _veterinarioController,
                      decoration: const InputDecoration(
                        labelText: 'Veterinário responsável',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _data,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _data = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child:
                                  Text(DateFormat('dd/MM/yyyy').format(_data)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _custoController,
                            decoration: const InputDecoration(
                              labelText: 'Custo (R\$)',
                              prefixIcon: Icon(Icons.attach_money),
                              helperText: 'Gera despesa em Financeiro',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const ['Em andamento', 'Concluído']
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
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
                      label: const Text('Salvar Registro'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
