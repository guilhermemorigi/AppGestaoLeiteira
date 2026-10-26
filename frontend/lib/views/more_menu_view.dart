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

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.98,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          return Card(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => e.page),
              ),
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
          );
        },
      ),
    );
  }
}
