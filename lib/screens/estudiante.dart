import 'package:flutter/material.dart';
import 'consultar_equipos.dart';
import 'mis_prestamos.dart';

class EstudianteScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String usuario; // username visible
  final String usuarioId; // ID real del estudiante
  final String rol;

  const EstudianteScreen({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.usuarioId,
    required this.rol,
  });

  @override
  State<EstudianteScreen> createState() => _EstudianteScreenState();
}

class _EstudianteScreenState extends State<EstudianteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B7BE5),
        title: const Text(
          'Panel del Estudiante',
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
                // username (visible)
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
                    color: Color(0xFFE0E6F8),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Bienvenido",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "${widget.nombre} ${widget.apellido}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B7BE5),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // 🔹 Consultar disponibilidad
              ElevatedButton.icon(
                key: Key('btn_est_consultar_disponibilidad'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConsultarEquiposScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.computer, color: Colors.white),
                label: const Text(
                  "Consultar Disponibilidad",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7BE5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 Consultar mis préstamos
              ElevatedButton.icon(
                key: Key('btn_est_mis_prestamos'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MisPrestamosScreen(
                        usuarioId: widget.usuarioId, // ID real para filtrar
                        usuario: widget.usuario, // username visible
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt, color: Colors.white),
                label: const Text(
                  "Consultar Mis Préstamos",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
