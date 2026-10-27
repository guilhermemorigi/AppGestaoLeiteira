import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'theme/app_theme.dart';
import 'views/dashboard_view.dart';
import 'views/animal_list_view.dart';
import 'views/production_list_view.dart';
import 'views/login_view.dart';
import 'views/expense_list_view.dart';
import 'views/more_menu_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Leiteira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginView(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  /// Abas já visitadas. Cada aba só é montada na 1ª visita e depois fica
  /// viva no IndexedStack: trocar de aba não recria a tela nem baixa tudo
  /// de novo (as abas se atualizam sozinhas via ApiService.alteracoes).
  final Set<int> _abasVisitadas = {0};

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardView(),
    AnimalListView(),
    ProductionListView(),
    ExpenseListView(),
    MoreMenuView(),
  ];

  final List<String> _titles = [
    'Dashboard de Produção',
    'Animais Cadastrados',
    'Registros de Produção',
    'Controle de Gastos',
    'Mais Funcionalidades',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _abasVisitadas.add(index);
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_selectedIndex],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var i = 0; i < _widgetOptions.length; i++)
            _abasVisitadas.contains(i)
                ? _widgetOptions[i]
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Relatório',
          ),
          NavigationDestination(
            icon: Icon(MdiIcons.cow),
            selectedIcon: Icon(MdiIcons.cow),
            label: 'Animais',
          ),
          const NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Produção',
          ),
          const NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Financeiro',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}
