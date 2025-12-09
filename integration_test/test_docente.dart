import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gestion_inventario_prestamos_patrick/main.dart';

void main() {
  testWidgets('Validación básica del flujo del docente (sin login real)',
      (tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Validar que la pantalla de login carga correctamente
    expect(find.byKey(Key('login_cedula')), findsOneWidget);
    expect(find.byKey(Key('login_password')), findsOneWidget);
    expect(find.byKey(Key('login_btn')), findsOneWidget);

    // Como NO se realizó login real, los botones del docente NO deben aparecer todavía
    expect(find.byKey(Key('btn_registrar_prestamo')), findsNothing);
    expect(find.byKey(Key('btn_consultar_prestamos')), findsNothing);
    expect(find.byKey(Key('btn_registrar_devolucion')), findsNothing);
  });
}
