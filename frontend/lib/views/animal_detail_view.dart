import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'animal_form_view.dart';
import 'health_form_view.dart';
import 'vaccine_form_view.dart';
import 'reproduction_form_view.dart';
import 'production_form_view.dart';

class AnimalDetailView extends StatefulWidget {
  final Animal animal;
  const AnimalDetailView({super.key, required this.animal});

  @override
  State<AnimalDetailView> createState() => _AnimalDetailViewState();
}

class _AnimalDetailViewState extends State<AnimalDetailView> {
  late Animal _animal;
  List<Production> _history = [];
  List<HealthRecord> _health = [];
  List<Vaccine> _vaccines = [];
  List<Reproduction> _reproduction = [];
  double _totalProduction = 0;
  double _averageProduction = 0;
  bool _isLoading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getProductionByAnimal(_animal.id!),
        _api.getHealthByAnimal(_animal.id!),
        _api.getVaccinesByAnimal(_animal.id!),
        _api.getReproductionByAnimal(_animal.id!),
      ]);
      final production = results[0] as List<Production>;
      final total = production.fold(0.0, (s, p) => s + p.quantidade);
      if (!mounted) return;
      setState(() {
        _history = production;
        _health = results[1] as List<HealthRecord>;
        _vaccines = results[2] as List<Vaccine>;
        _reproduction = results[3] as List<Reproduction>;
        _totalProduction = total;
        _averageProduction = production.isEmpty ? 0 : total / production.length;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(describeError(e,
                  fallback: 'Erro ao carregar dados do animal.'))),
        );
      }
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnimalFormView(animal: _animal)),
    );
    if (result == true) await _reloadAnimal();
  }

  /// Recarrega o cadastro (o status pode mudar, ex.: parto → Lactação).
  Future<void> _reloadAnimal() async {
    try {
      final atualizado = await _api.getAnimal(_animal.id!);
      if (mounted) setState(() => _animal = atualizado);
    } catch (_) {
      // mantém os dados atuais se a recarga falhar
    }
    _loadData();
  }

  Future<void> _quickAdd(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) _reloadAnimal();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern('pt_BR');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Ficha: ${_animal.nome}',
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _edit,
              tooltip: 'Editar',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Produção', icon: Icon(Icons.water_drop)),
              Tab(text: 'Saúde', icon: Icon(Icons.health_and_safety)),
              Tab(text: 'Vacinas', icon: Icon(Icons.vaccines)),
              Tab(text: 'Reprodução', icon: Icon(Icons.favorite)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(nf),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildProductionTab(nf),
                        _buildHealthTab(),
                        _buildVaccinesTab(),
                        _buildReproductionTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(NumberFormat nf) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primary.withOpacity(0.06),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: Icon(MdiIcons.cow, size: 34, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_animal.nome,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    StatusChip(_animal.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    '${_animal.raca} • ${_animal.sexo ?? "-"} • ${_animal.idade} anos'
                    '${_animal.numeroBrinco?.isNotEmpty == true ? " • Brinco ${_animal.numeroBrinco}" : ""}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniStat(Icons.water_drop,
                        '${nf.format(_totalProduction)} L', AppTheme.blue),
                    const SizedBox(width: 16),
                    _miniStat(
                        Icons.speed,
                        '${nf.format(_averageProduction)} L/dia',
                        AppTheme.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _tabScaffold(
      {required List items,
      required Widget list,
      required String emptyMsg,
      required IconData emptyIcon,
      required VoidCallback onAdd,
      required String addLabel,
      required Color color}) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: items.isEmpty
          ? EmptyState(icon: emptyIcon, message: emptyMsg)
          : RefreshIndicator(onRefresh: _loadData, child: list),
      floatingActionButton: FloatingActionButton.small(
        onPressed: onAdd,
        backgroundColor: color,
        tooltip: addLabel,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductionTab(NumberFormat nf) {
    return _tabScaffold(
      items: _history,
      emptyIcon: Icons.water_drop_outlined,
      emptyMsg: 'Nenhum registro de produção',
      color: AppTheme.blue,
      addLabel: 'Registrar produção',
      onAdd: () => _quickAdd(ProductionFormView(animal: _animal)),
      list: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = _history[i];
          return ListTile(
            onTap: () => _quickAdd(ProductionFormView(production: p)),
            leading: const Icon(Icons.calendar_today,
                size: 20, color: AppTheme.blue),
            title: Text(DateFormat('dd/MM/yyyy').format(p.data)),
            trailing: Text('${nf.format(p.quantidade)} L',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildHealthTab() {
    return _tabScaffold(
      items: _health,
      emptyIcon: Icons.health_and_safety_outlined,
      emptyMsg: 'Nenhum registro de saúde',
      color: AppTheme.red,
      addLabel: 'Registrar saúde',
      onAdd: () => _quickAdd(HealthFormView(animal: _animal)),
      list: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _health.length,
        itemBuilder: (context, i) {
          final r = _health[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => _quickAdd(HealthFormView(record: r)),
              leading: const Icon(Icons.local_hospital, color: AppTheme.red),
              title: Text(r.descricao,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${r.tipo} • ${DateFormat('dd/MM/yyyy').format(r.data)}'),
              trailing: StatusChip(r.status),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVaccinesTab() {
    return _tabScaffold(
      items: _vaccines,
      emptyIcon: Icons.vaccines_outlined,
      emptyMsg: 'Nenhuma vacina registrada',
      color: AppTheme.teal,
      addLabel: 'Registrar vacina',
      onAdd: () => _quickAdd(VaccineFormView(animal: _animal)),
      list: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _vaccines.length,
        itemBuilder: (context, i) {
          final v = _vaccines[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => _quickAdd(VaccineFormView(vaccine: v)),
              leading: const Icon(Icons.vaccines, color: AppTheme.teal),
              title: Text(v.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Aplicada em ${DateFormat('dd/MM/yyyy').format(v.dataAplicacao)}'
                  '${v.proximaDose != null ? "\nPróxima: ${DateFormat('dd/MM/yyyy').format(v.proximaDose!)}" : ""}'),
              isThreeLine: v.proximaDose != null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReproductionTab() {
    return _tabScaffold(
      items: _reproduction,
      emptyIcon: Icons.favorite_outline,
      emptyMsg: 'Nenhum registro reprodutivo',
      color: AppTheme.purple,
      addLabel: 'Registrar reprodução',
      onAdd: () => _quickAdd(ReproductionFormView(animal: _animal)),
      list: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _reproduction.length,
        itemBuilder: (context, i) {
          final r = _reproduction[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () => _quickAdd(ReproductionFormView(record: r)),
              leading: const Icon(Icons.favorite, color: AppTheme.purple),
              title: Text(r.tipo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat('dd/MM/yyyy').format(r.data)}'
                  '${r.previsaoParto != null ? "\nPrevisão de parto: ${DateFormat('dd/MM/yyyy').format(r.previsaoParto!)}" : ""}'),
              isThreeLine: r.previsaoParto != null,
              trailing: StatusChip(r.status),
            ),
          );
        },
      ),
    );
  }
}
