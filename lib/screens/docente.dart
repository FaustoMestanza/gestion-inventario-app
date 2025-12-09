import 'package:flutter/material.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/consultar_prestamos.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/historial_devoluciones.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/scan_qr_devolucion.dart';
import 'package:gestion_inventario_prestamos_patrick/screens/registrar_prestamo.dart';

class DocenteScreen extends StatefulWidget {
  final int docenteId; // ✅ ID real del docente logueado
  final String nombre;
  final String apellido;
  final String usuario;
  final String rol;

  const DocenteScreen({
    super.key,
    required this.docenteId,
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.rol,
  });

  @override
  State<DocenteScreen> createState() => _DocenteScreenState();
}

class _DocenteScreenState extends State<DocenteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B7BE5),
        title: const Text(
          'Panel del Docente',
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
              const SizedBox(height: 50),

              // 🔹 Registrar Préstamo
              _buildButton(
                key: Key('btn_registrar_prestamo'),
                label: "Registrar Préstamo",
                icon: Icons.assignment_add,
                color: const Color(0xFF4B7BE5),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrarPrestamoScreen(
                        docenteId: widget.docenteId, // ✅ enviar el ID
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 🔹 Consultar Préstamos
              _buildButton(
                key: Key('btn_consultar_prestamos'),
                label: "Consultar Préstamos",
                icon: Icons.list_alt,
                color: const Color(0xFF00B894),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConsultarPrestamosScreen(
                        docenteId: widget
                            .docenteId, // ✅ enviamos el ID del docente logueado
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 🔹 Registrar Devolución
              _buildButton(
                key: Key('btn_registrar_devolucion'),
                label: "Registrar Devolución",
                icon: Icons.assignment_turned_in,
                color: const Color(0xFF00B894),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanQRDevolucionScreen(
                        docenteId: widget.docenteId, // ✅ ID del docente
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 🔹 Historial de Devoluciones
              _buildButton(
                key: Key('btn_historial_devoluciones'),
                label: "Historial de Devoluciones",
                icon: Icons.history,
                color: const Color(0xFF4B7BE5),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistorialDevolucionesScreen(
                        docenteId:
                            widget.docenteId, // ✅ ID del docente logueado
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    Key? key,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
