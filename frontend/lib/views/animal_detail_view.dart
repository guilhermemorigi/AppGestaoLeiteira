import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AnimalDetailView extends StatefulWidget {
  final Animal animal;
  const AnimalDetailView({super.key, required this.animal});

  @override
  State<AnimalDetailView> createState() => _AnimalDetailViewState();
}

class _AnimalDetailViewState extends State<AnimalDetailView> {
  List<Production> _history = [];
  double _totalProduction = 0;
  double _averageProduction = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getProductionByAnimal(widget.animal.id!);
      final total = data.fold(0.0, (sum, p) => sum + p.quantidade);
      setState(() {
        _history = data;
        _totalProduction = total;
        _averageProduction = data.isEmpty ? 0 : total / data.length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao carregar histórico do animal.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('pt_BR');

    return Scaffold(
      appBar: AppBar(title: Text('Ficha: ${widget.animal.nome}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.green[50],
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            child: Icon(MdiIcons.cow, size: 40),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.animal.nome,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text('Raça: ${widget.animal.raca}'),
                              Text('Idade: ${widget.animal.idade} anos'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              'Total Produzido',
                              '${numberFormat.format(_totalProduction)} L',
                              Icons.water_drop,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              'Média Diária',
                              '${numberFormat.format(_averageProduction)} L',
                              Icons.speed,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Histórico de Produção',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const Divider(),
                    _history.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                                'Nenhum registro encontrado para este animal.'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final p = _history[index];
                              return ListTile(
                                leading:
                                    const Icon(Icons.calendar_today, size: 20),
                                title: Text(
                                    DateFormat('dd/MM/yyyy').format(p.data)),
                                trailing: Text(
                                  '${numberFormat.format(p.quantidade)} L',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
