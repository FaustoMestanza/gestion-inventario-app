import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormularioEquipoScreen extends StatefulWidget {
  final Map<String, dynamic> equipo;
  //final int directorId; // ✅ Nuevo campo

  const FormularioEquipoScreen({
    super.key,
    required this.equipo,
    // required this.directorId,
  });

  @override
  State<FormularioEquipoScreen> createState() => _FormularioEquipoScreenState();
}

class _FormularioEquipoScreenState extends State<FormularioEquipoScreen> {
  late TextEditingController nombreController;
  late TextEditingController categoriaController;
  late TextEditingController descripcionController;
  late TextEditingController ubicacionController;
  late TextEditingController estadoController;

  @override
  void initState() {
    super.initState();
    nombreController =
        TextEditingController(text: widget.equipo['nombre'] ?? '');
    categoriaController =
        TextEditingController(text: widget.equipo['categoria'] ?? '');
    descripcionController =
        TextEditingController(text: widget.equipo['descripcion'] ?? '');
    ubicacionController =
        TextEditingController(text: widget.equipo['ubicacion'] ?? '');
    estadoController =
        TextEditingController(text: widget.equipo['estado'] ?? 'Disponible');
  }

  Future<void> _guardarCambios() async {
    final id = widget.equipo['id'];
    final url =
        //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/$id/';
        'https://apigateway-tesis.azure-api.net/inventario/api/equipos/$id/';

    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombreController.text,
        'categoria': categoriaController.text,
        'descripcion': descripcionController.text,
        'ubicacion': ubicacionController.text,
        'estado': estadoController.text,
        // 'registradoPor_id':
        //  widget.directorId, // ✅ Aquí se envía el ID del director
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Equipo registrado correctamente')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('⚠️ Error al registrar: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7F32),
        title: Text('Registrar equipo ${widget.equipo['codigo']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _campo('Nombre', nombreController),
            _campo('Categoría', categoriaController),
            _campo('Descripción', descripcionController),
            _campo('Ubicación', ubicacionController),
            _campo('Estado', estadoController),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7F32),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Guardar equipo',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
