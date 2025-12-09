import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'director.dart';
import 'docente.dart';
import 'estudiante.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Endpoint real en Azure
  final String _loginUrl =
      //'https://microservicio-usuarios-gsbhdjavc9fjf9a8.brazilsouth-01.azurewebsites.net/api/v1/auth/login/';
      'https://apigateway-tesis.azure-api.net/usuarios/api/v1/auth/login/';

  Future<void> enviarTokenNotificacion(int usuarioId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🔥 SOLICITAR PERMISOS ANTES DE OBTENER TOKEN
    await messaging.requestPermission();

    String? token = await messaging.getToken();

    if (token == null) return;

    await http.post(
      Uri.parse(
          "https://microservicio-usuarios-gsbhdjavc9fjf9a8.brazilsouth-01.azurewebsites.net/api/v1/registrar_token/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario_id": usuarioId, "token": token}),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cedula': _cedulaController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access'];
        final rol = data['user']['rol']?.toLowerCase();

        // Redirige según el rol
        if (rol == 'director') {
          final user = data['user'];
          await enviarTokenNotificacion(user['id']);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectorScreen(
                nombre: user['first_name'],
                apellido: user['last_name'],
                usuario: user['username'],
                rol: user['rol'],
                //directorId: user['id'], // ✅ se pasa el ID del usuario logueado
              ),
            ),
          );
        } else if (rol == 'docente') {
          final user = data['user'];
          await enviarTokenNotificacion(user['id']);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocenteScreen(
                nombre: user['first_name'],
                apellido: user['last_name'],
                usuario: user['username'],
                rol: user['rol'],
                docenteId: user[
                    'id'], // ✅ este campo viene del backend (ID del usuario)
              ),
            ),
          );
        } else if (rol == 'estudiante') {
          final user = data['user'];
          await enviarTokenNotificacion(user['id']);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EstudianteScreen(
                nombre: user["first_name"],
                apellido: user["last_name"],
                usuario: user["username"], // visible
                usuarioId: user["id"].toString(), // ID real para consultas
                rol: user["rol"],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol no reconocido.')),
          );
        }

        debugPrint('Token JWT: $accessToken');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: const Color(0xFF6A5AE0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: Key('login_cedula'),
              controller: _cedulaController,
              decoration: const InputDecoration(
                labelText: 'Cédula',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: Key('login_password'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    key: Key('login_btn'),
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5AE0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Ingresar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
