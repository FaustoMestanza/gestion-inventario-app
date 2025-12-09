import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetalleDevolucionScreen extends StatefulWidget {
  final Map<String, dynamic> prestamo; // JSON del préstamo abierto
  final int docenteId;

  const DetalleDevolucionScreen({
    super.key,
    required this.prestamo,
    required this.docenteId,
  });

  @override
  State<DetalleDevolucionScreen> createState() =>
      _DetalleDevolucionScreenState();
}

class _DetalleDevolucionScreenState extends State<DetalleDevolucionScreen> {
  final TextEditingController observacionCtrl = TextEditingController();
  final TextEditingController condicionCtrl =
      TextEditingController(text: 'Bueno');
  final TextEditingController sancionCtrl = TextEditingController();

  bool cargando = false;
  bool vencido = false;

  // 🔗 Endpoints
  final String devolucionesURL =
      'https://apigateway-tesis.azure-api.net/devoluciones/devoluciones/';
  final String prestamosURL =
      'https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/';
  final String inventarioURL =
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';

  @override
  void initState() {
    super.initState();
    _evaluarVencimientoLocal();
  }

  void _evaluarVencimientoLocal() {
    try {
      final fcStr = widget.prestamo['fecha_compromiso']?.toString();
      if (fcStr == null || fcStr.isEmpty) return;
      DateTime fc = DateTime.parse(fcStr);
      fc = fc.isUtc ? fc : fc.toUtc();
      final ahora = DateTime.now().toUtc();
      setState(() {
        vencido = ahora.isAfter(fc);
      });
    } catch (_) {
      vencido = false;
    }
  }

  Future<void> _registrar() async {
    if (vencido && (sancionCtrl.text.trim().isEmpty)) {
      _msg('El préstamo está vencido. Ingrese sanción en puntos.');
      return;
    }

    final prestamoId = widget.prestamo['id'];
    final equipoId = widget.prestamo['equipo_id'];

    final body = {
      'prestamo_id': prestamoId,
      'recibidoPor_id': widget.docenteId,
      'observacion': observacionCtrl.text.trim(),
      'condicion': condicionCtrl.text.trim(),
      'prestamo_vencido': vencido,
      'sancion_puntos':
          vencido ? double.tryParse(sancionCtrl.text.trim()) ?? 0 : 0,
    };

    setState(() => cargando = true);
    try {
      // 1) Crear devolución
      final r = await http.post(
        Uri.parse(devolucionesURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (r.statusCode != 201) {
        final data = _safeJson(r.body);
        _msg('No se pudo registrar: ${data['mensaje'] ?? r.statusCode}');
        setState(() => cargando = false);
        return;
      }

      // 2) Equipo → Disponible
      await http.patch(
        Uri.parse('$inventarioURL$equipoId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': 'Disponible'}),
      );

      // 3) Préstamo → Cerrado
      final cierre = await http.patch(
        Uri.parse('$prestamosURL$prestamoId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': 'Cerrado'}),
      );

      // 🔍 DEBUG CIERRE (AQUÍ SE MUESTRA LO IMPORTANTE)
      print("🔴 STATUS CIERRE: ${cierre.statusCode}");
      print("🔴 BODY CIERRE: ${cierre.body}");

      _msg('✅ Devolución registrada correctamente.');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _msg('Error de conexión: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  Map<String, dynamic> _safeJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _msg(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Devolución'),
        backgroundColor: const Color(0xFF00B894),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Préstamo: ${p['id']}'),
                  Text('Equipo ID: ${p['equipo_id']}'),
                  Text('Usuario ID: ${p['usuario_id']}'),
                  Text('Fecha compromiso: ${p['fecha_compromiso']}'),
                  Text('Estado actual: ${p['estado']}'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('¿Vencido?: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(vencido ? 'Sí' : 'No',
                          style: TextStyle(
                            color: vencido ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: observacionCtrl,
            decoration: const InputDecoration(
              labelText: 'Observación',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: condicionCtrl,
            decoration: const InputDecoration(
              labelText: 'Condición del equipo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (vencido)
            TextField(
              controller: sancionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sanción (puntos)',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: cargando ? null : _registrar,
            icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
            label: Text(cargando ? 'Registrando...' : 'Registrar Devolución'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}
