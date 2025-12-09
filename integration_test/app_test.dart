import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gestion_inventario_prestamos_patrick/main.dart';

void main() {
  testWidgets('Flujo general de navegación (sin login real)', (tester) async {
    // Iniciar la app
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // --------------------------
    // 1. Validar que la pantalla de LOGIN carga bien
    // --------------------------
    expect(find.byKey(Key('login_cedula')), findsOneWidget);
    expect(find.byKey(Key('login_password')), findsOneWidget);
    expect(find.byKey(Key('login_btn')), findsOneWidget);

    // --------------------------
    // 2. Validar que la app NO se cae y muestra el título LOGIN
    // --------------------------
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // --------------------------
    // 3. Validación de que los botones de otros roles NO existen aún
    // (esto evita falsos positivos)
    // --------------------------
    expect(find.byKey(Key('btn_registrar_prestamo')), findsNothing);
    expect(find.byKey(Key('btn_consultar_prestamos')), findsNothing);
    expect(find.byKey(Key('btn_registrar_devolucion')), findsNothing);

    expect(find.byKey(Key('btn_registrar_inventario')), findsNothing);
    expect(find.byKey(Key('btn_operaciones_inventario')), findsNothing);

    expect(find.byKey(Key('btn_est_consultar_disponibilidad')), findsNothing);
    expect(find.byKey(Key('btn_est_mis_prestamos')), findsNothing);

    // Fin del test
  });
}
