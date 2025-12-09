import 'package:flutter/material.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/scanQr.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/listar_equipos.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/buscar_equipo.dart';

class DirectorScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String usuario;
  final String rol;
  //final int directorId; // 👈 NUEVO

  const DirectorScreen({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.rol,
    // required this.directorId, // 👈 NUEVO
  });

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  bool mostrarOperaciones = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7F32),
        title: const Text(
          'Panel del Director',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.usuario,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.rol,
                  style: const TextStyle(
                    color: Color(0xFFFFEBD8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                "Bienvenido, ${widget.nombre} ${widget.apellido}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // 🔸 Botón Registrar Inventario
              ElevatedButton.icon(
                key: Key('btn_registrar_inventario'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanQRScreen(
                          // directorId: widget.directorId, // ✅ Pasamos el ID
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                label: const Text(
                  "Registrar Inventario",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7F32),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 Botón principal de operaciones
              ElevatedButton.icon(
                key: Key('btn_operaciones_inventario'),
                onPressed: () {
                  setState(() {
                    mostrarOperaciones = !mostrarOperaciones;
                  });
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text(
                  "Operaciones sobre Inventario",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),

              // 🔻 Botones que aparecen debajo
              if (mostrarOperaciones) ...[
                const SizedBox(height: 25),

                // 🟧 Listar equipos
                ElevatedButton.icon(
                  key: Key('btn_listar_equipos'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListarEquiposScreen(
                            // directorId: widget
                            //.directorId, // 👈 aquí mandamos el ID del usuario logueado
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list, color: Colors.white),
                  label: const Text(
                    "Listar Equipos",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),

                const SizedBox(height: 15),

                // 🟪 Buscar equipo
                // 🟣 Buscar equipo
                ElevatedButton.icon(
                  key: Key('btn_buscar_equipo'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BuscarEquipoScreen(
                            //directorId: widget
                            //.directorId, // ✅ Pasamos el ID del usuario logueado
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text(
                    "Buscar Equipo",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
