import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_gestao_leiteira/theme/app_theme.dart';
import 'package:app_gestao_leiteira/views/more_menu_view.dart';

/// Garante que os cards do menu "Mais" não estouram (RenderFlex overflow)
/// em telas estreitas nem com fonte ampliada nas configurações do celular.
void main() {
  const telas = {
    'celular pequeno (320 dp)': Size(320, 640),
    'celular comum (360 dp)': Size(360, 740),
    'celular grande (412 dp)': Size(412, 915),
  };

  for (final entry in telas.entries) {
    for (final escala in [1.0, 1.3]) {
      testWidgets('sem overflow: ${entry.key}, fonte x$escala', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: entry.value,
              textScaler: TextScaler.linear(escala),
            ),
            child: const MoreMenuView(),
          ),
        ));

        // Um overflow vira exceção capturada pelo framework de teste
        expect(tester.takeException(), isNull);
        expect(find.text('Saúde & Tratamentos'), findsOneWidget);
      });
    }
  }
}
