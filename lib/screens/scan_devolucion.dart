import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanDevolucionScreen extends StatefulWidget {
  final Map<String, dynamic> prestamo;
  final int docenteId;

  const ScanDevolucionScreen({
    super.key,
    required this.prestamo,
    required this.docenteId,
  });

  @override
  State<ScanDevolucionScreen> createState() => _ScanDevolucionScreenState();
}

class _ScanDevolucionScreenState extends State<ScanDevolucionScreen> {
  final TextEditingController observacionCtrl = TextEditingController();
  final TextEditingController condicionCtrl =
      TextEditingController(text: 'Bueno');
  final TextEditingController sancionCtrl = TextEditingController();

  bool cargando = false;
  bool vencido = false;
  String? nombreEquipo;
  String? nombreUsuario;

  final String devolucionesURL =
      //'https://microservicio-gestiondevolucion-ddbychb0a8anbwc8.brazilsouth-01.azurewebsites.net/devoluciones/';
      'https://apigateway-tesis.azure-api.net/devoluciones/devoluciones/';
  final String prestamosURL =
      //'https://microservicio-gestionprestamo-fmcxb0gvcshag6av.brazilsouth-01.azurewebsites.net/api/prestamos/';
      'https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/';
  final String inventarioURL =
      //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';
  final String usuariosURL =
      //'https://microservicio-usuarios-gsbhdjavc9fjf9a8.brazilsouth-01.azurewebsites.net/api/v1/usuarios/';
      'https://apigateway-tesis.azure-api.net/usuarios/api/v1/usuarios/';

  @override
  void initState() {
    super.initState();
    _evaluarVencimientoLocal();
    _cargarNombres();
  }

  void _evaluarVencimientoLocal() {
    try {
      final fcStr = widget.prestamo['fecha_compromiso']?.toString();
      if (fcStr == null || fcStr.isEmpty) return;
      final fc = DateTime.parse(fcStr);
      final ahora = DateTime.now();
      setState(() => vencido = ahora.isAfter(fc));
    } catch (_) {
      vencido = false;
    }
  }

  Future<void> _cargarNombres() async {
    final p = widget.prestamo;
    try {
      if (p['equipo_id'] != null) {
        final eqResp =
            await http.get(Uri.parse('$inventarioURL${p['equipo_id']}/'));
        if (eqResp.statusCode == 200) {
          final eq = jsonDecode(eqResp.body);
          setState(() => nombreEquipo = eq['nombre']);
        }
      }
      if (p['usuario_id'] != null) {
        final userResp =
            await http.get(Uri.parse('$usuariosURL${p['usuario_id']}/'));
        if (userResp.statusCode == 200) {
          final u = jsonDecode(userResp.body);
          setState(
              () => nombreUsuario = '${u['first_name']} ${u['last_name']}');
        }
      }
    } catch (e) {
      print('Error al cargar nombres: $e');
    }
  }

  Future<void> _registrar() async {
    if (vencido && sancionCtrl.text.trim().isEmpty) {
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
      final r = await http.post(
        Uri.parse(devolucionesURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (r.statusCode != 201) {
        _msg('No se pudo registrar: ${r.statusCode}');
        setState(() => cargando = false);
        return;
      }

      await http.patch(
        Uri.parse('$inventarioURL$equipoId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': 'Disponible'}),
      );

      await http.patch(
        Uri.parse('$prestamosURL$prestamoId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': 'Cerrado'}),
      );

      _msg('✅ Devolución registrada correctamente.');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _msg('Error de conexión: $e');
    } finally {
      setState(() => cargando = false);
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
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Préstamo: ${p['id']}'),
                  Text('Equipo ID: ${p['equipo_id']}'),
                  if (nombreEquipo != null)
                    Text('Nombre del equipo: $nombreEquipo',
                        style: const TextStyle(color: Colors.blue)),
                  Text('Usuario ID: ${p['usuario_id']}'),
                  if (nombreUsuario != null)
                    Text('Nombre del estudiante: $nombreUsuario',
                        style: const TextStyle(color: Colors.blue)),
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
          const SizedBox(height: 20),
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
