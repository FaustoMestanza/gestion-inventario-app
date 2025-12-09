import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HistorialDevolucionesScreen extends StatefulWidget {
  final int docenteId; // ✅ ID del docente logueado

  const HistorialDevolucionesScreen({super.key, required this.docenteId});

  @override
  State<HistorialDevolucionesScreen> createState() =>
      _HistorialDevolucionesScreenState();
}

class _HistorialDevolucionesScreenState
    extends State<HistorialDevolucionesScreen> {
  List<dynamic> devoluciones = [];
  bool cargando = true;

  // 🔗 URLs
  final String devolucionesURL =
      //'https://microservicio-gestiondevolucion-ddbychb0a8anbwc8.brazilsouth-01.azurewebsites.net/devoluciones/';
      'https://apigateway-tesis.azure-api.net/devoluciones/devoluciones/';
  final String usuariosURL =
      //'https://microservicio-usuarios-gsbhdjavc9fjf9a8.brazilsouth-01.azurewebsites.net/api/v1/usuarios/';
      'https://apigateway-tesis.azure-api.net/usuarios/api/v1/usuarios/';
  final String inventarioURL =
      //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';
  final String prestamosURL =
      //'https://microservicio-gestionprestamo-fmcxb0gvcshag6av.brazilsouth-01.azurewebsites.net/api/prestamos/';
      'https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/';

  @override
  void initState() {
    super.initState();
    _cargarDevoluciones();
  }

  String _formatearFecha(dynamic fecha) {
    try {
      if (fecha == null) return 'N/D';
      final parsed = DateTime.parse(fecha.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return 'N/D';
    }
  }

  Future<void> _cargarDevoluciones() async {
    try {
      final resp = await http.get(Uri.parse(devolucionesURL));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;

        // 🔹 Filtrar solo las devoluciones registradas por el docente logueado
        final misDevoluciones = data.where((d) {
          final recibidoPor = d['recibidoPor_id'];
          return recibidoPor != null && recibidoPor == widget.docenteId;
        }).toList();

        List<dynamic> enriquecidas = [];

        for (var d in misDevoluciones) {
          String? nombreEquipo;
          String? nombreUsuario;
          String? fechaPrestamo;
          String? estadoPrestamo;

          try {
            final int prestamoId = d['prestamo_id'];
            final pResp =
                await http.get(Uri.parse('$prestamosURL$prestamoId/'));

            if (pResp.statusCode == 200) {
              final p = jsonDecode(pResp.body);

              final equipoId = p['equipo_id'];
              final usuarioId = p['usuario_id'];
              fechaPrestamo = p['fecha_inicio'];
              estadoPrestamo = p['estado'];

              // 🔹 Nombre del equipo
              if (equipoId != null) {
                final eqResp =
                    await http.get(Uri.parse('$inventarioURL$equipoId/'));
                if (eqResp.statusCode == 200) {
                  final eq = jsonDecode(eqResp.body);
                  nombreEquipo = eq['nombre'] ?? 'Desconocido';
                }
              }

              // 🔹 Nombre del estudiante
              if (usuarioId != null) {
                final userResp =
                    await http.get(Uri.parse('$usuariosURL$usuarioId/'));
                if (userResp.statusCode == 200) {
                  final u = jsonDecode(userResp.body);
                  nombreUsuario =
                      '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
                }
              }
            }
          } catch (e) {
            print('Error al obtener detalles: $e');
          }

          // 🔹 Agregar datos enriquecidos
          d['nombre_equipo'] = nombreEquipo;
          d['nombre_usuario'] = nombreUsuario;
          d['fecha_prestamo'] = fechaPrestamo;
          d['estado_prestamo'] = estadoPrestamo;
          enriquecidas.add(d);
        }

        setState(() {
          devoluciones = enriquecidas;
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al obtener devoluciones (${resp.statusCode})')),
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Devoluciones Registradas'),
        backgroundColor: const Color(0xFF4B7BE5),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : devoluciones.isEmpty
              ? const Center(
                  child: Text(
                    'No has registrado devoluciones.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: devoluciones.length,
                  itemBuilder: (context, index) {
                    final d = devoluciones[index];

                    final double sancionValor =
                        double.tryParse('${d['sancion_puntos'] ?? 0}') ?? 0;
                    final sancion =
                        sancionValor > 0 ? 'Sí (${sancionValor} pts)' : 'No';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['nombre_usuario'] ?? 'Estudiante desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '💻 Equipo: ${d['nombre_equipo'] ?? "Sin nombre"}'),
                            Text(
                                '📅 Fecha préstamo: ${_formatearFecha(d['fecha_prestamo'])}'),
                            Text(
                                '📅 Fecha devolución: ${_formatearFecha(d['fecha'])}'),
                            Text(
                                '📋 Estado del préstamo: ${d['estado_prestamo'] ?? "N/D"}'),
                            Text(
                                '📝 Observación: ${d['observacion'] ?? "Sin observación"}'),
                            Text('⚠️ Sanción: $sancion'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
