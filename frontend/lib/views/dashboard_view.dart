import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  double _totalGeral = 0;
  double _averageProduction = 0;
  String _topAnimal = "---";
  double _topAnimalQty = 0;

  Map<String, double> _dailyTotals = {};
  List<FlSpot> _chartData = [];
  List<String> _chartLabels = [];
  List<Production> _allProductions = [];

  String _currentFilter = '7d';
  bool _isLoading = true;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final productions = await _apiService.getAllProduction();
      _allProductions = productions;
      _computeStats();
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar dados do servidor.')),
        );
      }
    }
  }

  void _computeStats() {
    final now = DateTime.now();
    DateTime start;

    if (_currentFilter == '7d') {
      start = now.subtract(const Duration(days: 6));
    } else if (_currentFilter == '30d') {
      start = now.subtract(const Duration(days: 29));
    } else {
      start = DateTime(now.year, now.month, 1);
    }

    final startDay = DateFormat('yyyy-MM-dd').format(start);
    final endDay = DateFormat('yyyy-MM-dd').format(now);

    final filtered = _allProductions.where((p) {
      final pDay = DateFormat('yyyy-MM-dd').format(p.data);
      return pDay.compareTo(startDay) >= 0 && pDay.compareTo(endDay) <= 0;
    }).toList();

    final Map<String, double> daily = {};
    for (var p in filtered) {
      final day = DateFormat('yyyy-MM-dd').format(p.data);
      daily[day] = (daily[day] ?? 0) + p.quantidade;
    }

    final total = filtered.fold(0.0, (sum, p) => sum + p.quantidade);

    final Map<String, double> animalTotals = {};
    final Map<String, String> animalNames = {};
    for (var p in filtered) {
      final key = p.animalId.toString();
      animalTotals[key] = (animalTotals[key] ?? 0) + p.quantidade;
      animalNames[key] = p.animalNome;
    }

    String topAnimalName = "---";
    double topAnimalQty = 0;
    if (animalTotals.isNotEmpty) {
      final top =
          animalTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      topAnimalName = animalNames[top.key] ?? "---";
      topAnimalQty = top.value;
    }

    final sortedKeys = daily.keys.toList()..sort();
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), daily[sortedKeys[i]]!));
      labels.add(DateFormat('dd/MM').format(DateTime.parse(sortedKeys[i])));
    }

    setState(() {
      _totalGeral = total;
      _dailyTotals = daily;
      _chartData = spots;
      _chartLabels = labels;
      _averageProduction = daily.isEmpty ? 0 : total / daily.length;
      _topAnimal = topAnimalName;
      _topAnimalQty = topAnimalQty;
      _isLoading = false;
    });
  }

  void _showDetailsDialog(String dateStr, String formattedDate) {
    final details = _allProductions
        .where((p) => DateFormat('yyyy-MM-dd').format(p.data) == dateStr)
        .toList();
    final numberFormat = NumberFormat.decimalPattern('pt_BR');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Detalhes: $formattedDate'),
        content: SizedBox(
          width: double.maxFinite,
          child: details.isEmpty
              ? const Text('Nenhum registro encontrado.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: details.length,
                  itemBuilder: (context, i) {
                    final item = details[i];
                    return ListTile(
                      leading: Icon(MdiIcons.cow, color: Colors.blueGrey),
                      title: Text(item.animalNome),
                      trailing: Text(
                        '${numberFormat.format(item.quantidade)} L',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('pt_BR');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterButton('7 Dias', '7d'),
                        const SizedBox(width: 8),
                        _buildFilterButton('30 Dias', '30d'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Mês Atual', 'mes'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryCard(
                          "TOTAL PERÍODO",
                          "${numberFormat.format(_totalGeral)} L",
                          Colors.green,
                          Icons.opacity,
                        ),
                        _buildSummaryCard(
                          "MÉDIA DIÁRIA",
                          "${numberFormat.format(_averageProduction)} L",
                          Colors.blue,
                          Icons.trending_up,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTopAnimalCard(numberFormat),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Evolução da Produção',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  'Média: ${numberFormat.format(_averageProduction)}L',
                                  style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 220,
                              child: _chartData.isEmpty
                                  ? const Center(
                                      child: Text("Sem dados no período"))
                                  : LineChart(_mainChartData()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Histórico do Período',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._dailyTotals.entries.toList().reversed.map((entry) {
                      final date = DateTime.parse(entry.key);
                      final formattedDate =
                          DateFormat('dd/MM/yyyy').format(date);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () =>
                              _showDetailsDialog(entry.key, formattedDate),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[50],
                            child: const Icon(Icons.calendar_month,
                                color: Colors.green),
                          ),
                          title: Text(formattedDate,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${numberFormat.format(entry.value)} Litros produzidos'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 14),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _currentFilter = value;
          _computeStats();
        }
      },
      selectedColor: Colors.green[700],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildTopAnimalCard(NumberFormat nf) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[50],
          child: Icon(MdiIcons.trophy, color: Colors.orange[800]),
        ),
        title: const Text('Animal Destaque do Período',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(_topAnimal,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${nf.format(_topAnimalQty)} L',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange)),
            const Text('Total', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _chartLabels.length) {
                if (_currentFilter == '7d' ||
                    index % 5 == 0 ||
                    index == _chartLabels.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_chartLabels[index],
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 10)),
                  );
                }
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: _averageProduction,
            color: Colors.blue.withOpacity(0.5),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: false,
              alignment: Alignment.topRight,
              style: const TextStyle(color: Colors.blue, fontSize: 10),
            ),
          ),
        ],
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _chartData,
          isCurved: true,
          gradient:
              const LinearGradient(colors: [Colors.green, Colors.lightGreen]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.3),
                Colors.green.withOpacity(0.0)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
