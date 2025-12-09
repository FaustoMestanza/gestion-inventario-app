import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'formulario_equipo.dart';

class ScanQRScreen extends StatefulWidget {
  //final int directorId; // ✅ ID del docente logueado

  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen>
    with SingleTickerProviderStateMixin {
  bool isProcessing = false;
  final MobileScannerController cameraController = MobileScannerController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _buscarEquipo(String codigo) async {
    try {
      print('Código detectado: $codigo');

      final url =
          //'https://microservicio-gestioninventario-e7byadgfgdhpfyen.brazilsouth-01.azurewebsites.net/api/equipos/?codigo=$codigo';
          'https://apigateway-tesis.azure-api.net/inventario/api/equipos/?codigo=$codigo';

      final response = await http.get(Uri.parse(url));

      print('Respuesta ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data = [];

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.isNotEmpty) {
          data = [decoded];
        }

        if (data.isNotEmpty) {
          final equipo = Map<String, dynamic>.from(data.first);

          final yaRegistrado = (equipo['nombre'] != null &&
                  equipo['nombre'].toString().trim().isNotEmpty) ||
              (equipo['categoria'] != null &&
                  equipo['categoria'].toString().trim().isNotEmpty) ||
              (equipo['descripcion'] != null &&
                  equipo['descripcion'].toString().trim().isNotEmpty) ||
              (equipo['ubicacion'] != null &&
                  equipo['ubicacion'].toString().trim().isNotEmpty);

          if (yaRegistrado) {
            _mostrarMensaje(
                '⚠️ El equipo ${equipo['codigo']} ya está registrado.');
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FormularioEquipoScreen(
                  equipo: equipo,
                  // directorId: widget.directorId, // ✅ se pasa el ID del docente
                ),
              ),
            );
          }
        } else {
          _mostrarMensaje('No se encontró el equipo con código $codigo');
        }
      } else {
        _mostrarMensaje('Error ${response.statusCode} al buscar equipo');
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    }

    setState(() => isProcessing = false);
    cameraController.start();
  }

  void _mostrarMensaje(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7F32),
        title: const Text('Escanear Código QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isProcessing) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() => isProcessing = true);
                  cameraController.stop();
                  _buscarEquipo(code);
                }
              }
            },
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(250, 250),
                  painter: _QRGuidePainter(_animation.value),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Apunta la cámara hacia el código QR del equipo',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRGuidePainter extends CustomPainter {
  final double progress;
  _QRGuidePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint border = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint line = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, border);

    final double y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
