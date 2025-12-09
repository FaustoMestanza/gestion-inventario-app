import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gestion_inventario_prestamos_patrick/main.dart';

void main() {
  testWidgets('Validación básica del flujo del estudiante (sin login real)',
      (tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Validar que la pantalla de login cargó correctamente
    expect(find.byKey(Key('login_cedula')), findsOneWidget);
    expect(find.byKey(Key('login_password')), findsOneWidget);
    expect(find.byKey(Key('login_btn')), findsOneWidget);

    // Como NO se hizo login real, estos widgets NO deben existir todavía
    expect(find.byKey(Key('btn_est_consultar_disponibilidad')), findsNothing);
    expect(find.byKey(Key('btn_est_mis_prestamos')), findsNothing);

    // Test exitoso
  });
}
