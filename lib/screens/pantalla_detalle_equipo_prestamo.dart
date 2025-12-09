import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetalleEquipoPrestamoScreen extends StatefulWidget {
  final Map<String, dynamic> equipo;
  final Function(String) onRegistrar;
  final int docenteId; // ✅ ID del docente logueado

  const DetalleEquipoPrestamoScreen({
    super.key,
    required this.equipo,
    required this.onRegistrar,
    required this.docenteId,
  });

  @override
  State<DetalleEquipoPrestamoScreen> createState() =>
      _DetalleEquipoPrestamoScreenState();
}

class _DetalleEquipoPrestamoScreenState
    extends State<DetalleEquipoPrestamoScreen> {
  final TextEditingController cedulaController = TextEditingController();
  bool cargando = false;

  // 🌐 URLs de microservicios
  final String usuariosURL =
      //'https://microservicio-usuarios-gsbhdjavc9fjf9a8.brazilsouth-01.azurewebsites.net/api/v1/usuarios/';
      'https://apigateway-tesis.azure-api.net/usuarios/api/v1/usuarios/';
  final String prestamosURL =
      //'https://microservicio-gestionprestamo-fmcxb0gvcshag6av.brazilsouth-01.azurewebsites.net/api/prestamos/';
      'https://apigateway-tesis.azure-api.net/prestamos/api/prestamos/';
  final String inventarioURL =
      //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';
      'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';

  /// 🔍 Buscar usuario por cédula
  Future<Map<String, dynamic>?> _buscarUsuarioPorCedula(String cedula) async {
    try {
      final response = await http.get(Uri.parse(usuariosURL));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        // Buscar usuario con rol estudiante y cédula coincidente
        final usuario = data.firstWhere(
          (u) {
            final rol = u['rol']?.toString().toLowerCase() ?? '';
            final cedulaDB = u['cedula']?.toString().trim() ?? '';
            return rol == 'estudiante' && cedulaDB == cedula.trim();
          },
          orElse: () => {},
        );

        if (usuario.isNotEmpty) {
          debugPrint(
              '✅ Estudiante encontrado: ${usuario['first_name']} ${usuario['last_name']}');
          return usuario;
        } else {
          debugPrint('❌ No se encontró estudiante con cédula $cedula');
        }
      } else {
        debugPrint('❌ Error HTTP al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error buscando usuario: $e');
    }
    return null;
  }

  /// 💾 Registrar préstamo
  Future<void> _registrarPrestamo() async {
    final cedula = cedulaController.text.trim();

    if (cedula.isEmpty) {
      _mostrarMensaje('Por favor, ingresa la cédula del estudiante.');
      return;
    }

    setState(() => cargando = true);

    final usuario = await _buscarUsuarioPorCedula(cedula);
    if (usuario == null) {
      setState(() => cargando = false);
      _mostrarMensaje('❌ Estudiante no encontrado.');
      return;
    }

    final usuarioId = usuario['id'];

    try {
      final body = {
        "equipo_id": widget.equipo['id'],
        "usuario_id": usuarioId,
        "registrado_por_id": widget.docenteId.toString(), // ✅ Docente logueado
        "fecha_compromiso":
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(prestamosURL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        // ✅ Actualizar estado del equipo a "Prestado"
        final patchResponse = await http.patch(
          Uri.parse('$inventarioURL${widget.equipo['id']}/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'estado': 'Prestado'}),
        );

        if (patchResponse.statusCode == 200) {
          _mostrarMensaje('✅ Préstamo registrado y equipo actualizado.');
        } else {
          _mostrarMensaje(
              '⚠️ Préstamo creado, pero no se actualizó el estado del equipo.');
        }

        Navigator.pop(context);
      } else {
        _mostrarMensaje(
            '❌ Error al registrar préstamo: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarMensaje('⚠️ Error de conexión: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final equipo = widget.equipo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B7BE5),
        title: const Text('Registrar Préstamo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🖥️ Información del equipo
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Código: ${equipo['codigo']}'),
                  Text(
                      'Descripción: ${equipo['descripcion'] ?? 'Sin descripción'}'),
                  Text('Categoría: ${equipo['categoria'] ?? 'N/A'}'),
                  Text('Ubicación: ${equipo['ubicacion'] ?? 'N/A'}'),
                  Text('Estado: ${equipo['estado']}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // 🧍 Campo para ingresar cédula
          TextField(
            controller: cedulaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cédula del estudiante',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          // 🔘 Botón Registrar
          ElevatedButton.icon(
            onPressed: cargando ? null : _registrarPrestamo,
            icon: const Icon(Icons.assignment_add, color: Colors.white),
            label: cargando
                ? const Text("Registrando...")
                : const Text("Registrar Préstamo"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B7BE5),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
