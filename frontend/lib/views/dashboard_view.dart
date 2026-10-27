import 'dart:math';

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
  // Litros sempre com 1 casa decimal no formato brasileiro (ex.: 1.234,5 L)
  static final _litros =
      NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 1);
  static final _eixo = NumberFormat.decimalPattern('pt_BR');
  static String _l(double valor) => '${_litros.format(valor)} L';
  // Formatadores criados uma vez só (criar DateFormat por item é caro)
  static final _diaMes = DateFormat('dd/MM');
  static final _dataCompleta = DateFormat('dd/MM/yyyy');

  double _totalGeral = 0;
  double _averageProduction = 0;
  String _topAnimal = "---";
  double _topAnimalQty = 0;

  /// Produção agrupada por dia (data sem hora). Montada uma vez por carga da
  /// API; trocar de filtro só recorta o intervalo de dias.
  Map<DateTime, List<Production>> _porDia = {};

  /// Dias do filtro atual, do mais recente para o mais antigo (histórico).
  List<DateTime> _diasPeriodo = [];
  Map<DateTime, double> _totaisPorDia = {};
  List<FlSpot> _chartData = [];
  List<String> _chartLabels = [];

  String _currentFilter = '7d';
  bool _isLoading = true;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Aba fica viva na navegação: recarrega quando qualquer dado muda
    ApiService.alteracoes.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    ApiService.alteracoes.removeListener(_loadData);
    super.dispose();
  }

  /// Carga em andamento: chamadas simultâneas (aviso de alteração + retorno
  /// de um formulário) reaproveitam a mesma requisição em vez de repetir.
  Future<void>? _cargaAtual;

  Future<void> _loadData() =>
      _cargaAtual ??= _carregar().whenComplete(() => _cargaAtual = null);

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Baixa só o período que o dashboard exibe: o mais longo entre
      // "30 dias" e "mês atual" (e não todo o histórico de produção)
      final agora = DateTime.now();
      final trintaDias = DateTime(agora.year, agora.month, agora.day - 29);
      final inicioMes = DateTime(agora.year, agora.month, 1);
      final productions = await _apiService.getAllProduction(
          desde: trintaDias.isBefore(inicioMes) ? trintaDias : inicioMes);
      final porDia = <DateTime, List<Production>>{};
      for (final p in productions) {
        final dia = DateTime(p.data.year, p.data.month, p.data.day);
        (porDia[dia] ??= []).add(p);
      }
      _porDia = porDia;
      if (!mounted) return;
      _computeStats();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(describeError(e,
                  fallback: 'Erro ao carregar dados do servidor.'))),
        );
      }
    }
  }

  void _computeStats() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicio = switch (_currentFilter) {
      '7d' => DateTime(hoje.year, hoje.month, hoje.day - 6),
      '30d' => DateTime(hoje.year, hoje.month, hoje.day - 29),
      _ => DateTime(hoje.year, hoje.month, 1),
    };

    // Só os dias do período (comparação de DateTime, sem converter em texto)
    final dias = _porDia.keys
        .where((d) => !d.isBefore(inicio) && !d.isAfter(hoje))
        .toList()
      ..sort();

    final totais = <DateTime, double>{};
    final totalPorAnimal = <int, double>{};
    final nomes = <int, String>{};
    var total = 0.0;
    for (final dia in dias) {
      var soma = 0.0;
      for (final p in _porDia[dia]!) {
        soma += p.quantidade;
        totalPorAnimal[p.animalId] =
            (totalPorAnimal[p.animalId] ?? 0) + p.quantidade;
        nomes[p.animalId] = p.animalNome;
      }
      totais[dia] = soma;
      total += soma;
    }

    String topAnimalName = "---";
    double topAnimalQty = 0;
    if (totalPorAnimal.isNotEmpty) {
      final top =
          totalPorAnimal.entries.reduce((a, b) => a.value > b.value ? a : b);
      topAnimalName = nomes[top.key] ?? "---";
      topAnimalQty = top.value;
    }

    setState(() {
      _totalGeral = total;
      _totaisPorDia = totais;
      _diasPeriodo = dias.reversed.toList();
      _chartData = [
        for (var i = 0; i < dias.length; i++)
          FlSpot(i.toDouble(), totais[dias[i]]!)
      ];
      _chartLabels = [for (final d in dias) _diaMes.format(d)];
      _averageProduction = dias.isEmpty ? 0 : total / dias.length;
      _topAnimal = topAnimalName;
      _topAnimalQty = topAnimalQty;
      _isLoading = false;
    });
  }

  void _showDetailsDialog(DateTime dia) {
    final details = _porDia[dia] ?? const <Production>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Detalhes: ${_dataCompleta.format(dia)}'),
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
                      title: Text(item.animalNome,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(
                        _l(item.quantidade),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(child: _buildResumo()),
                  ),
                  // Histórico montado sob demanda: só os cards visíveis são criados
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.builder(
                      itemCount: _diasPeriodo.length,
                      itemBuilder: (context, i) =>
                          _buildDiaCard(_diasPeriodo[i]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Filtros, cards de resumo, gráfico e o título do histórico.
  Widget _buildResumo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wrap: os filtros descem para a linha de baixo se não couberem
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterButton('7 Dias', '7d'),
            _buildFilterButton('30 Dias', '30d'),
            _buildFilterButton('Mês Atual', 'mes'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard(
              "TOTAL PERÍODO",
              _l(_totalGeral),
              Colors.green,
              Icons.opacity,
            ),
            _buildSummaryCard(
              "MÉDIA DIÁRIA",
              _l(_averageProduction),
              Colors.blue,
              Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTopAnimalCard(),
        const SizedBox(height: 24),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Evolução da Produção',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Média: ${_l(_averageProduction)}',
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
                      ? const Center(child: Text("Sem dados no período"))
                      // Isola o redesenho do gráfico da rolagem da tela
                      : RepaintBoundary(child: LineChart(_mainChartData())),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Histórico do Período',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDiaCard(DateTime dia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showDetailsDialog(dia),
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: const Icon(Icons.calendar_month, color: Colors.green),
        ),
        title: Text(_dataCompleta.format(dia),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${_litros.format(_totaisPorDia[dia] ?? 0)} litros produzidos'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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

  Widget _buildTopAnimalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[50],
          child: Icon(MdiIcons.trophy, color: Colors.orange[800]),
        ),
        title: const Text('Animal destaque',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(_topAnimal,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        // Largura máxima + FittedBox: números grandes diminuem em vez de estourar
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_l(_topAnimalQty),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange)),
                const Text('Total', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Escala do eixo Y: começa em zero (o gráfico tem área preenchida) e usa
  /// passos "redondos" (1, 2 ou 5 x 10^n), resultando em 4 a 5 linhas de grade.
  ({double max, double passo}) get _escalaY {
    final maior =
        _chartData.isEmpty ? 0.0 : _chartData.map((s) => s.y).reduce(max);
    if (maior <= 0) return (max: 10, passo: 5);
    final bruto = maior / 4;
    final potencia = pow(10, (log(bruto) / ln10).floor()).toDouble();
    final f = bruto / potencia;
    final passo = (f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 5 ? 5 : 10))) * potencia;
    return (max: (maior / passo).ceil() * passo, passo: passo);
  }

  LineChartData _mainChartData() {
    final escala = _escalaY;
    return LineChartData(
      minY: 0,
      maxY: escala.max,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: escala.passo,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        // Eixo de litros: inteiros, formato brasileiro, numa linha só
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: escala.passo,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(_eixo.format(value),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (value != index.toDouble()) return const SizedBox();
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
          // A curva não passa acima/abaixo dos valores reais entre os pontos
          preventCurveOverShooting: true,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              // Valores grandes encolhem para caber numa linha só
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
