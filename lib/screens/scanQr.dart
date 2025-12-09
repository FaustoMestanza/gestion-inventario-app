import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'formulario_equipo.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

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

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================
  // 📌 Buscar equipo en la API
  // ===========================================================
  Future<void> _buscarEquipo(String codigo) async {
    try {
      final url =
          "https://apigateway-tesis.azure-api.net/inventario/api/equipos/?codigo=$codigo";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.isNotEmpty) {
          data = [decoded];
        }

        if (data.isEmpty) {
          _mostrarMensaje("No se encontró el equipo con código $codigo");
          return;
        }

        final equipo = Map<String, dynamic>.from(data.first);

        final yaRegistrado =
            (equipo['nombre'] ?? "").toString().trim().isNotEmpty ||
                (equipo['categoria'] ?? "").toString().trim().isNotEmpty ||
                (equipo['descripcion'] ?? "").toString().trim().isNotEmpty ||
                (equipo['ubicacion'] ?? "").toString().trim().isNotEmpty;

        if (yaRegistrado) {
          _mostrarMensaje(
              "⚠️ El equipo ${equipo['codigo']} ya está registrado.");
          return;
        }

        // ➜ Ir al formulario
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormularioEquipoScreen(equipo: equipo),
          ),
        );

        // Reactivar cámara al volver
        cameraController.start();
      } else {
        _mostrarMensaje("Error ${response.statusCode} al consultar equipo.");
      }
    } catch (e) {
      _mostrarMensaje("Error de conexión: $e");
    }
  }

  // ===========================================================
  // 📷 Cuando se detecta un QR
  // ===========================================================
  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final code = capture.barcodes.first.rawValue;

    if (code != null && code.isNotEmpty) {
      isProcessing = true;
      cameraController.stop();

      await _buscarEquipo(code);

      isProcessing = false;
    }
  }

  // ===========================================================
  // 🧱 UI
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7F32),
        title: const Text("Escanear Código QR"),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Marco animado
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
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
                "Apunta la cámara hacia el código QR del equipo",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// =======================================================
// 🎨 Marco del escáner
// =======================================================
class _QRGuidePainter extends CustomPainter {
  final double progress;

  _QRGuidePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final line = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), border);

    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
