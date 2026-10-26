import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'reminder_list_view.dart';
import 'stock_list_view.dart';
import 'health_list_view.dart';
import 'vaccine_list_view.dart';
import 'reproduction_list_view.dart';
import 'user_list_view.dart';

class _MenuEntry {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  const _MenuEntry(this.label, this.subtitle, this.icon, this.color, this.page);
}

/// Tela-hub com atalhos para os módulos secundários do app.
class MoreMenuView extends StatelessWidget {
  const MoreMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_MenuEntry>[
      const _MenuEntry('Saúde & Tratamentos', 'Doenças, exames e cuidados',
          Icons.health_and_safety, AppTheme.red, HealthListView()),
      const _MenuEntry('Vacinação', 'Calendário e doses', Icons.vaccines,
          AppTheme.teal, VaccineListView()),
      const _MenuEntry('Reprodução', 'Cio, gestação e partos', Icons.favorite,
          AppTheme.purple, ReproductionListView()),
      const _MenuEntry('Estoque', 'Ração, insumos e medicamentos',
          Icons.inventory_2, AppTheme.primary, StockListView()),
      const _MenuEntry('Agenda / Manejo', 'Lembretes e tarefas',
          Icons.calendar_month, AppTheme.blue, ReminderListView()),
      const _MenuEntry('Usuários', 'Controle de acesso', Icons.group,
          AppTheme.orange, UserListView()),
    ];

    // Grade de 2 colunas em que a altura vem do conteúdo (e não de uma
    // proporção fixa): títulos que quebram linha ou fonte ampliada no
    // celular não estouram o card. Os dois cards da linha ficam com a
    // altura do maior.
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < entries.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _MenuCard(entries[i])),
                    const SizedBox(width: 14),
                    Expanded(
                      child: i + 1 < entries.length
                          ? _MenuCard(entries[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuCard(this.entry);

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => e.page),
        ),
        child: ConstrainedBox(
          // Mantém o visual "quadrado" quando o conteúdo é pequeno
          constraints: const BoxConstraints(minHeight: 150),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(e.icon, size: 34, color: e.color),
                ),
                const SizedBox(height: 12),
                Text(
                  e.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  e.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
