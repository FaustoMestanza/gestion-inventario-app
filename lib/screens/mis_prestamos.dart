//estudiante
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MisPrestamosScreen extends StatefulWidget {
  final String usuarioId; // ← ID REAL DEL ESTUDIANTE
  final String usuario; // ← username (opcional para mostrar si quieres)

  const MisPrestamosScreen({
    super.key,
    required this.usuarioId,
    required this.usuario,
  });

  @override
  State<MisPrestamosScreen> createState() => _MisPrestamosScreenState();
}

class _MisPrestamosScreenState extends State<MisPrestamosScreen> {
  static const String prestamosURL =
      //"https://microservicio-gestionprestamo-fmcxb0gvcshag6av.brazilsouth-01.azurewebsites.net/api/prestamos/";
      "https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/";

  static const String devolucionesURL =
      //"https://microservicio-gestiondevolucion-ddbychb0a8anbwc8.brazilsouth-01.azurewebsites.net/devoluciones/";
      "https://apigateway-tesis.azure-api.net/devoluciones/devoluciones/";

  static const String inventarioURL =
      //"https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/";
      "https://apigateway-tesis.azure-api.net/inventario/api/equipos/";

  late Future<List<Map<String, dynamic>>> prestamosCompletos;

  @override
  void initState() {
    super.initState();
    prestamosCompletos = cargarPrestamosCompletos();
  }

  // 🔥 UNE PRÉSTAMO + DEVOLUCIÓN + EQUIPO
  Future<List<Map<String, dynamic>>> cargarPrestamosCompletos() async {
    final prestamosRes = await http.get(Uri.parse(prestamosURL));
    final devolucionesRes = await http.get(Uri.parse(devolucionesURL));
    final inventarioRes = await http.get(Uri.parse(inventarioURL));

    if (prestamosRes.statusCode != 200 ||
        devolucionesRes.statusCode != 200 ||
        inventarioRes.statusCode != 200) {
      throw Exception("Error consultando los microservicios");
    }

    final prestamos = jsonDecode(prestamosRes.body);
    final devoluciones = jsonDecode(devolucionesRes.body);
    final equipos = jsonDecode(inventarioRes.body);

    // 🔥 Filtrar préstamos DEL ESTUDIANTE usando usuarioId real
    final prestamosUsuario = prestamos
        .where((p) => p["usuario_id"].toString() == widget.usuarioId)
        .toList();

    List<Map<String, dynamic>> resultado = [];

    for (var p in prestamosUsuario) {
      final equipo = equipos.firstWhere(
        (e) => e["id"] == p["equipo_id"],
        orElse: () => null,
      );

      final devolucion = devoluciones.firstWhere(
        (d) => d["prestamo_id"] == p["id"],
        orElse: () => null,
      );

      resultado.add({
        "prestamo_id": p["id"],
        "equipo_nombre":
            equipo != null ? equipo["nombre"] : "Equipo desconocido",
        "laboratorio": equipo != null ? equipo["ubicacion"] : "N/A",
        "estado_prestamo": p["estado"],
        "fecha_inicio": p["fecha_inicio"],
        "fecha_compromiso": p["fecha_compromiso"],
        "fecha_devolucion": devolucion != null ? devolucion["fecha"] : null,
        "condicion":
            devolucion != null ? devolucion["condicion"] : "Sin registro",
        "sancion": devolucion != null
            ? "${devolucion["sancion_puntos"]} puntos"
            : "Sin sanción",
        "prestamo_vencido":
            devolucion != null ? devolucion["prestamo_vencido"] : false,
      });
    }

    return resultado;
  }

  String formatFecha(String? iso) {
    if (iso == null) return "-";
    try {
      DateTime dt = DateTime.parse(iso);
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year}";
    } catch (e) {
      return "-";
    }
  }

  Color estadoColor(String estado) {
    estado = estado.toLowerCase();
    if (estado.contains("abierto")) return Colors.blue;
    if (estado.contains("cerrado")) return Colors.green;
    if (estado.contains("vencido")) return Colors.red;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Préstamos"),
        backgroundColor: const Color(0xFF00BFA6),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: prestamosCompletos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Error cargando préstamos:\n${snapshot.error}"));
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(
              child: Text("No tienes préstamos registrados."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final p = lista[index];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p["equipo_nombre"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text("Laboratorio: ${p["laboratorio"]}"),
                      const SizedBox(height: 10),
                      Text("Inicio: ${formatFecha(p["fecha_inicio"])}"),
                      Text("Compromiso: ${formatFecha(p["fecha_compromiso"])}"),
                      Text(
                        "Devolución: ${formatFecha(p["fecha_devolucion"])}",
                        style: TextStyle(
                          color: p["fecha_devolucion"] != null
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 12),
                        decoration: BoxDecoration(
                          color: estadoColor(p["estado_prestamo"])
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p["estado_prestamo"],
                          style: TextStyle(
                            color: estadoColor(p["estado_prestamo"]),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sanción: ${p["sancion"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p["sancion"] != "Sin sanción"
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                      Text("Condición: ${p["condicion"]}"),
                    ],
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
