import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AnimalFormView extends StatefulWidget {
  final Animal? animal; // se informado, edição
  const AnimalFormView({super.key, this.animal});

  @override
  State<AnimalFormView> createState() => _AnimalFormViewState();
}

class _AnimalFormViewState extends State<AnimalFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _racaController = TextEditingController();
  final _brincoController = TextEditingController();
  final _pesoController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _sexo = 'Fêmea';
  String _status = 'Ativo';
  DateTime? _dataNascimento;
  bool _isSaving = false;

  final _statuses = const ['Ativo', 'Lactação', 'Seco', 'Vendido', 'Morto'];

  bool get _isEdit => widget.animal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    if (a != null) {
      _nomeController.text = a.nome;
      _idadeController.text = a.idade.toString();
      _racaController.text = a.raca;
      _brincoController.text = a.numeroBrinco ?? '';
      _pesoController.text = a.peso?.toString() ?? '';
      _sexo = a.sexo ?? 'Fêmea';
      _status = _statuses.contains(a.status) ? a.status : 'Ativo';
      _dataNascimento = a.dataNascimento;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _racaController.dispose();
    _brincoController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final animal = Animal(
      id: widget.animal?.id,
      nome: _nomeController.text.trim(),
      idade: int.tryParse(_idadeController.text) ?? 0,
      raca: _racaController.text.trim(),
      numeroBrinco: _brincoController.text.trim().isEmpty
          ? null
          : _brincoController.text.trim(),
      sexo: _sexo,
      peso: double.tryParse(_pesoController.text.replaceAll(',', '.')),
      dataNascimento: _dataNascimento,
      status: _status,
    );

    try {
      if (_isEdit) {
        await _apiService.updateAnimal(widget.animal!.id!, animal);
      } else {
        await _apiService.createAnimal(animal);
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
      appBar:
          CustomAppBar(title: _isEdit ? 'Editar Animal' : 'Cadastrar Animal'),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome ou Identificação',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brincoController,
                            decoration: const InputDecoration(
                              labelText: 'Nº do brinco',
                              prefixIcon: Icon(Icons.tag),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _idadeController,
                            decoration: const InputDecoration(
                              labelText: 'Idade (anos)',
                              prefixIcon: Icon(Icons.cake),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _racaController,
                      decoration: const InputDecoration(
                        labelText: 'Raça',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _sexo,
                            decoration: InputDecoration(
                              labelText: 'Sexo',
                              prefixIcon: Icon(MdiIcons.genderMaleFemale),
                            ),
                            items: const ['Fêmea', 'Macho']
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() => _sexo = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pesoController,
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              prefixIcon: Icon(Icons.monitor_weight),
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
                        labelText: 'Situação',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _statuses
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataNascimento ?? DateTime.now(),
                          firstDate: DateTime(2005),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && mounted) {
                          setState(() => _dataNascimento = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de nascimento (opcional)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    _dataNascimento == null
                                        ? 'Não informada'
                                        : DateFormat('dd/MM/yyyy')
                                            .format(_dataNascimento!),
                                    overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label:
                          Text(_isEdit ? 'Salvar Alterações' : 'Salvar Animal'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
