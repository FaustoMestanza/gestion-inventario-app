import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'formulario_equipo.dart';

class ListarEquiposScreen extends StatefulWidget {
  //final int directorId; // 👈 ID del usuario logueado (director)

  const ListarEquiposScreen({
    super.key,
    // required this.directorId,
  });

  @override
  State<ListarEquiposScreen> createState() => _ListarEquiposScreenState();
}

class _ListarEquiposScreenState extends State<ListarEquiposScreen> {
  List equipos = [];
  bool loading = true;

  Future<void> _cargarEquipos() async {
    final url =
        //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/';
        'https://apigateway-tesis.azure-api.net/inventario/api/equipos/';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        equipos = jsonDecode(response.body); // 👈 trae TODOS los equipos
        loading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar: ${response.statusCode}')),
      );
      setState(() => loading = false);
    }
  }

  Future<void> _eliminarEquipo(int id) async {
    final url =
        //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/$id/';
        'https://apigateway-tesis.azure-api.net/inventario/api/equipos/$id/';

    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Equipo eliminado correctamente.')),
      );
      _cargarEquipos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${response.statusCode}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarEquipos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Equipos'),
        backgroundColor: const Color(0xFFFF7F32),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: equipos.length,
              itemBuilder: (context, index) {
                final equipo = equipos[index];
                return Card(
                  child: ListTile(
                    title: Text(equipo['codigo']),
                    subtitle: Text(equipo['nombre'] ?? 'Sin nombre'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormularioEquipoScreen(
                                  equipo: equipo,
                                  // directorId: widget
                                  // .directorId, // 👈 se pasa el ID al formulario
                                ),
                              ),
                            ).then((_) => _cargarEquipos());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarEquipo(equipo['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
