// estudiante
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsultarEquiposScreen extends StatefulWidget {
  const ConsultarEquiposScreen({super.key});

  @override
  State<ConsultarEquiposScreen> createState() => _ConsultarEquiposScreenState();
}

class _ConsultarEquiposScreenState extends State<ConsultarEquiposScreen> {
  late Future<List<dynamic>> _futureEquipos;

  //static const String _inventarioBaseUrl =
  //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';

  static const String _inventarioBaseUrl =
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';

  @override
  void initState() {
    super.initState();
    _futureEquipos = _fetchEquipos();
  }

  Future<List<dynamic>> _fetchEquipos() async {
    final response = await http.get(Uri.parse(_inventarioBaseUrl));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("No se pudieron cargar los equipos.");
    }
  }

  Color _estadoColor(String estado) {
    estado = estado.toLowerCase();
    if (estado.contains("disponible")) return Colors.green;
    if (estado.contains("prestado")) return Colors.red;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consultar Disponibilidad"),
        backgroundColor: const Color(0xFF4B7BE5),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<List<dynamic>>(
        future: _futureEquipos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error al cargar equipos:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final equipos = snapshot.data ?? [];

          if (equipos.isEmpty) {
            return const Center(child: Text("No hay equipos registrados."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: equipos.length,
            itemBuilder: (context, index) {
              final equipo = equipos[index];

              final nombre = equipo["nombre"] ?? "Sin nombre";
              final laboratorio = equipo["ubicacion"] ?? "Sin ubicación";
              final estado = equipo["estado"] ?? "Sin estado";

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.computer, size: 35),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Laboratorio: $laboratorio",
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _estadoColor(estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _estadoColor(estado)),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: _estadoColor(estado),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
