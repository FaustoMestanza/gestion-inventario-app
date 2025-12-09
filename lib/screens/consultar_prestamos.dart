import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConsultarPrestamosScreen extends StatefulWidget {
  final int docenteId; // ✅ ID del docente logueado

  const ConsultarPrestamosScreen({super.key, required this.docenteId});

  @override
  State<ConsultarPrestamosScreen> createState() =>
      _ConsultarPrestamosScreenState();
}

class _ConsultarPrestamosScreenState extends State<ConsultarPrestamosScreen> {
  List<dynamic> prestamos = [];
  bool cargando = true;

  // 🌐 URLs de microservicios
  //final String prestamosURL =
  //'https://microservicio-gestionprestamo-fmcxb0gvcshag6av.brazilsouth-01.azurewebsites.net/api/prestamos/';
  final String prestamosURL =
      'https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/';
  //final String usuariosURL =
  //'https://microservicio-usuarios-gsbhdjavc9fjf9a8.brazilsouth-01.azurewebsites.net/api/v1/usuarios/';
  final String usuariosURL =
      'https://apigateway-tesis.azure-api.net/usuarios/api/v1/usuarios/';
  final String inventarioURL =
      //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';

  @override
  void initState() {
    super.initState();
    _cargarPrestamos();
  }

  Future<void> _cargarPrestamos() async {
    try {
      final response = await http.get(Uri.parse(prestamosURL));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        // 🔹 Filtrar solo los préstamos registrados por este docente
        final prestamosDocente = data.where((p) {
          final registradoPor = p['registrado_por_id'];
          return registradoPor != null && registradoPor == widget.docenteId;
        }).toList();

        // 🔹 Ordenar del más reciente al más antiguo
        prestamosDocente.sort((a, b) => DateTime.parse(b['fecha_inicio'])
            .compareTo(DateTime.parse(a['fecha_inicio'])));

        // 🔹 Enriquecer con datos del usuario y equipo
        final prestamosCompletos =
            await Future.wait(prestamosDocente.map((p) async {
          final usuario = await _obtenerUsuario(p['usuario_id']);
          final equipo = await _obtenerEquipo(p['equipo_id']);
          return {
            'id': p['id'],
            'estado': p['estado'],
            'fecha_inicio': p['fecha_inicio'],
            'fecha_compromiso': p['fecha_compromiso'],
            'usuario': usuario,
            'equipo': equipo,
          };
        }));

        setState(() {
          prestamos = prestamosCompletos;
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        _mostrarMensaje('Error al obtener préstamos (${response.statusCode})');
      }
    } catch (e) {
      setState(() => cargando = false);
      _mostrarMensaje('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> _obtenerUsuario(int id) async {
    try {
      final res = await http.get(Uri.parse('$usuariosURL$id/'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'first_name': 'Desconocido', 'last_name': '', 'curso': 'N/A'};
  }

  Future<Map<String, dynamic>> _obtenerEquipo(int id) async {
    try {
      final res = await http.get(Uri.parse('$inventarioURL$id/'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'nombre': 'Equipo no encontrado', 'codigo': 'N/A'};
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final f = DateTime.parse(fecha);
      return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B7BE5),
        title: const Text('Mis Préstamos Registrados'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : prestamos.isEmpty
              ? const Center(child: Text('No has registrado préstamos.'))
              : ListView.builder(
                  itemCount: prestamos.length,
                  itemBuilder: (context, index) {
                    final p = prestamos[index];
                    final usuario = p['usuario'];
                    final equipo = p['equipo'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.computer,
                            color: Color(0xFF4B7BE5)),
                        title: Text(
                          "${equipo['nombre']} (${equipo['codigo']})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Estudiante: ${usuario['first_name']} ${usuario['last_name']}"),
                              Text("Curso: ${usuario['curso'] ?? 'N/A'}"),
                              Text(
                                  "Fecha préstamo: ${_formatearFecha(p['fecha_inicio'])}"),
                              Text(
                                  "Fecha compromiso: ${_formatearFecha(p['fecha_compromiso'])}"),
                              Text("Estado: ${p['estado']}"),
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
